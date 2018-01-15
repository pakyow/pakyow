# frozen_string_literal: true

require "pakyow/support/makeable"

module Pakyow
  module Presenter
    # Decorates an object being bound to the view.
    #
    class Binder
      extend Support::Makeable

      # The object being bound.
      #
      attr_reader :object

      include Helpers

      def initialize(object)
        @object = object
        @parts = {}
      end

      # Defines a binding part, which binds to an aspect of the view.
      #
      # @example
      #   binder :post do
      #     def title(value)
      #       part :class do
      #         [:first_classname, :second_classname]
      #       end
      #
      #       part :content do
      #         value.to_s.reverse
      #       end
      #     end
      #   end
      #
      def part(name)
        parts_for(caller_locations(1, 1)[0].label.to_sym).define_part(name, yield)
      end

      # Returns the value for a key.
      #
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

      # Returns +true+ if the binder defines a value for +key+.
      #
      def include?(key)
        respond_to?(key) || @object.include?(key)
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
