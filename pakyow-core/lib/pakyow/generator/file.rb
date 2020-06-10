# frozen_string_literal: true

require "fileutils"
require "pathname"

module Pakyow
  class Generator
    # @api private
    class File
      require_relative "helpers"
      require_relative "processor"

      include Helpers

      attr_reader :path, :logical_path

      def initialize(path, source_path)
        @path = Pathname.new(path)

        @logical_path = Pathname.new(path).relative_path_from(
          Pathname.new(source_path)
        )
      end

      def generate(destination_path, context: self)
        generatable_path = Processor.reduce_path(populate_path(@logical_path, context: context))

        # Process the file.
        #
        processed_content = Processor.process(@path.read, context: context)

        # Build the generated file path.
        #
        destination_path_for_file = Pathname.new(destination_path).join(generatable_path)

        # Make sure the directory exists.
        #
        FileUtils.mkdir_p(destination_path_for_file.dirname)

        # Skip keep files.
        #
        unless generatable_path.basename.to_s == "keep"
          # Write the file.
          #
          destination_path_for_file.open("w+") do |file|
            file.write(processed_content)
          end
        end
      end

      PATH_VAR_REGEX = /%([^}]*)%/

      private def populate_path(path, context:)
        string_path = path.to_s
        string_path.scan(PATH_VAR_REGEX).each do |match|
          string_path.gsub!("%#{match[0]}%", context.public_send(match[0].to_sym))
        end

        Pathname.new(string_path)
      end
    end
  end
end
