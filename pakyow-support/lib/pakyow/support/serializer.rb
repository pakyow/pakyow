# frozen_string_literal: true

require "fileutils"

require "pakyow/support/logging"

module Pakyow
  module Support
    # Persists state for an object.
    #
    class Serializer
      attr_reader :object, :name, :path

      def initialize(object, name:, path:)
        @object, @name, @path = object, name, path
      end

      def serialize
        FileUtils.mkdir_p(@path)
        File.open(serialized_state_path, "w+") do |file|
          file.write(Marshal.dump(@object.serialize))
        end
      rescue => error
        Logging.yield_or_raise(error) do |logger|
          logger.error "[Serializer] failed to serialize `#{@name}': #{error}"
        end
      end

      def deserialize
        if File.exist?(serialized_state_path)
          Marshal.load(File.read(serialized_state_path)).each do |ivar, value|
            @object.instance_variable_set(ivar, value)
          end
        end
      rescue => error
        FileUtils.rm(serialized_state_path)
        Logging.yield_or_raise(error) do |logger|
          logger.error "[Serializer] failed to deserialize `#{@name}': #{error}"
        end
      end

      private

      def serialized_state_path
        File.join(@path, "#{@name}.pwstate")
      end
    end
  end
end
