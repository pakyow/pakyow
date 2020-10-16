# frozen_string_literal: true

require "fileutils"

module Pakyow
  module Support
    # Persists state for an object.
    #
    class Serializer
      attr_reader :object, :name, :path, :logger

      def initialize(object, name:, path:, logger:)
        @object, @name, @path, @logger = object, name, path, logger
      end

      def serialize
        FileUtils.mkdir_p(@path)
        File.open(serialized_state_path, "w+") do |file|
          file.write(Marshal.dump(@object.serialize))
        end
      rescue => error
        @logger.error "[Serializer] failed to serialize `#{@name}': #{error}"
      end

      def deserialize
        if File.exist?(serialized_state_path)
          Marshal.load(File.read(serialized_state_path)).each do |ivar, value|
            @object.instance_variable_set(ivar, value)
          end
        end
      rescue => error
        FileUtils.rm(serialized_state_path)
        @logger.error "[Serializer] failed to deserialize `#{@name}': #{error}"
      end

      private

      def serialized_state_path
        File.join(@path, "#{@name}.pwstate")
      end
    end
  end
end
