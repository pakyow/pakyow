# frozen_string_literal: true

require "pakyow/support/makeable"

module Pakyow
  module Presenter
    class Binder
      extend Support::Makeable

      attr_reader :object

      include Helpers

      def initialize(object)
        @object = object
        @parts = {}
      end

      def include?(key)
        respond_to?(key) || @object.include?(key)
      end

      def [](key)
        if respond_to?(key)
          value = __send__(key)

          if parts?(key)
            parts_for(key)
          else
            value
          end
        else
          @object[key]
        end
      end

      def part(name)
        parts_for(caller_locations(1, 1)[0].label.to_sym).define_part(name, yield)
      end

      private

      def parts?(name)
        @parts.include?(name)
      end

      def parts_for(name)
        @parts[name] ||= BindingParts.new
      end
    end
  end
end
