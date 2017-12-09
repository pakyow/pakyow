# frozen_string_literal: true

require "pakyow/ui/transformation"

module Pakyow
  module UI
    class Presenter
      def initialize(_call = nil, *_args)
        @transformations = []
      end

      def method_missing(method_name, *args, &block)
        transformation = Transformation.new(method_name, *args, &block)
        @transformations << transformation
        transformation
      end

      def to_arr
        @transformations.map(&:to_arr)
      end
    end
  end
end
