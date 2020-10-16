# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  # Evals the content of a file into a target.
  #
  class Loader
    require_relative "loader/context"

    extend Support::ClassState
    class_state :__loaded_paths, default: []

    attr_reader :path

    class << self
      def load_path(path, target:, pattern: "*.rb", reload: false)
        Dir.glob(File.join(path, pattern)).sort.each do |file_path|
          if reload || !@__loaded_paths.include?(file_path)
            Loader.new(file_path).call(target)
            @__loaded_paths << file_path
          end
        end

        Dir.glob(File.join(path, "*")).sort.select { |each_path|
          File.directory?(each_path)
        }.each do |directory_path|
          load_path(directory_path, target: target, pattern: pattern, reload: reload)
        end
      end

      def reset
        @__loaded_paths.clear
      end
    end

    def initialize(path)
      @path = path
    end

    def call(target)
      unless target.name
        raise ArgumentError, "cannot load `#{@path}' on unnamed target (`#{target}')"
      end

      Context.new(target, code, @path).load
    end

    private def code
      File.read(@path)
    end
  end
end
