# frozen_string_literal: true

require "fileutils"
require "pathname"

require "pakyow/support/cli/runner"
require "pakyow/support/class_state"
require "pakyow/support/hookable"
require "pakyow/support/inflector"

require_relative "operation"

module Pakyow
  # Base class for generators.
  #
  class Generator < Operation
    require_relative "generator/source"
    require_relative "generator/helpers"

    include Helpers

    extend Support::ClassState
    class_state :__source_paths, default: [], inheritable: true

    include Support::Hookable
    events :generate

    attr_reader :files

    # Define a source path for the generator.
    #
    def self.source_path(source_path)
      (__source_paths << Pathname.new(source_path)).uniq!
    end

    # Run the generator with its defined source paths.
    #
    def self.generate(destination, **options)
      new(*__source_paths, **options).generate(destination)
    end

    # Returns a normalized name suitable for generation.
    #
    def self.generatable_name(value)
      Support.inflector.underscore(value.downcase).gsub("  ", " ").tr(" ", "_")
    end

    def initialize(*source_paths, **options)
      @files = source_paths.flat_map { |source_path|
        source_path = Pathname.new(source_path)

        files = source_path.glob("**/*").reject(&:directory?).map { |path|
          Source.new(path, source_path)
        }

        if source_path.file?
          files << Source.new(source_path, source_path.dirname)
        end

        files
      }

      super(**options)
    end

    def perform(destination, *, **)
      destination = Pathname.new(destination)

      thread_localize(:destination, destination)

      performing :generate do
        FileUtils.mkdir_p(destination)

        @files.each do |file|
          file.generate(destination, context: self)
        end

        super
      ensure
        delete_thread_localized(:destination)
      end
    end
    alias_method :generate, :perform

    def run(command, message:, from: thread_localized(:destination, "."))
      Support::CLI::Runner.new(message: message).run(
        "cd #{from} && #{command}"
      )
    end
  end
end
