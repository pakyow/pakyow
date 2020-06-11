# frozen_string_literal: true

require "fileutils"
require "pathname"

require "pakyow/support/cli/runner"
require "pakyow/support/class_state"
require "pakyow/support/hookable"

require "pakyow/support/pipeline"

module Pakyow
  # Base class for generators.
  #
  class Generator
    require_relative "generator/file"
    require_relative "generator/helpers"

    include Helpers

    extend Support::ClassState
    class_state :__source_paths, default: [], inheritable: true

    include Support::Hookable
    events :generate

    include Support::Pipeline

    attr_reader :files

    # Define a source path for the generator.
    #
    def self.source_path(source_path)
      (__source_paths << Pathname.new(source_path)).uniq!
    end

    # Run the generator with its defined source paths.
    #
    def self.generate(destination_path, **options)
      new(*__source_paths).generate(destination_path, **options)
    end

    def initialize(*source_paths)
      @files = source_paths.flat_map { |source_path|
        source_path = Pathname.new(source_path)

        files = source_path.glob("**/*").reject(&:directory?).map { |path|
          File.new(path, source_path)
        }

        if source_path.file?
          files << File.new(source_path, source_path.dirname)
        end

        files
      }
    end

    def call(destination_path, **options)
      dup._generate(destination_path, **options)
    end
    alias generate call

    def run(command, message:)
      Support::CLI::Runner.new(message: message).run(
        "cd #{@destination_path} && #{command}"
      )
    end

    # @api private
    def _generate(destination_path, **options)
      @destination_path = Pathname.new(destination_path)

      options.each do |key, value|
        instance_variable_set(:"@#{key}", value)
      end

      performing :generate do
        FileUtils.mkdir_p(@destination_path)

        @files.each do |file|
          file.generate(@destination_path, context: self)
        end

        @__pipeline.call(self, destination_path, **options)
      end
    end
  end
end
