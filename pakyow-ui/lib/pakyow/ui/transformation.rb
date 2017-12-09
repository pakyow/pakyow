# frozen_string_literal: true

module Pakyow
  module UI
    class Transformation
      def initialize(call = nil, *args)
        @call = call
        @args = args
        @transformations = []

        instance_exec(&Proc.new) if block_given?
      end

      def method_missing(method_name, *args, &block)
        transformation = Transformation.new(method_name, *args, &block)
        @transformations << transformation
        transformation
      end

      def to_arr
        [@call, @args, @transformations.map(&:to_arr)]
      end
    end
  end
end
