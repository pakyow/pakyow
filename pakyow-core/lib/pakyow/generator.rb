# frozen_string_literal: true

require "fileutils"
require "pathname"

require "pakyow/support/cli/runner"
require "pakyow/support/hookable"

require "pakyow/support/pipeline"

module Pakyow
  # Base class for generators.
  #
  class Generator
    require_relative "generator/file"
    require_relative "generator/helpers"

    include Helpers

    include Support::Hookable
    events :generate

    include Support::Pipeline

    attr_reader :files

    def initialize(source_path)
      source_path = Pathname.new(source_path)

      @files = source_path.glob("**/*").reject(&:directory?).map { |path|
        File.new(path, source_path)
      }

      if source_path.file?
        @files << File.new(source_path, source_path.dirname)
      end
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
