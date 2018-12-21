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

      def initialize(object)
        @object = object
        @parts = {}
        @binding = false
        @memoized = {}
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
      def part(name, &block)
        parts_for(caller_locations(1, 1)[0].label.to_sym).define_part(name, block)
      end

      # Returns the value for a key (including parts).
      #
      def __value(key)
        if @memoized.include?(key)
          @memoized[key]
        else
          @memoized[key] = if respond_to?(key)
            value = public_send(key)

            if parts?(key)
              parts_for(key)
            else
              value
            end
          else
            @object[key]
          end
        end
      end

      # Returns the underlying object value for a key.
      #
      def [](key)
        @object[key]
      end

      # Returns only the content value for a key.
      #
      def __content(key, view)
        return_value = __value(key)
        if return_value.is_a?(BindingParts)
          if return_value.content?
            return_value.content(view)
          else
            @object[key]
          end
        else
          return_value
        end
      end

      # Returns +true+ if the binder might return a value for +key+.
      #
      def include?(key)
        return false if @binding && !@object.include?(key) && (parts?(key) && !parts_for(key).content?)
        respond_to?(key) || @object.include?(key)
      end

      # Returns +true+ if the a value is present for +key+.
      #
      def present?(key)
        !!__value(key)
      end

      # Flips a switch, telling the binder that we now only care about content, not other parts.
      # This is so that we can transform based on parts, but bind only based on content.
      #
      # @api private
      def binding!
        @binding = true
      end

      private

      def parts?(name)
        @parts.include?(name.to_sym)
      end

      def parts_for(name)
        @parts[name] ||= BindingParts.new
      end
    end
  end
end
