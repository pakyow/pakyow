# frozen_string_literal: true

module Pakyow
  module Presenter
    class BindingParts
      attr_reader :parts

      def initialize
        @parts = {}
      end

      def define_part(name, block)
        @parts[name] = block
      end

      def content?
        @parts.include?(:content)
      end

      def content(view)
        @parts[:content].call(view.text)
      end

      def values(view)
        values_for_parts(@parts, view)
      end

      def non_content_values(view)
        values_for_parts(@parts.reject { |name, _|
          name == :content
        }, view)
      end

      def reject(*parts)
        parts = parts.map(&:to_sym)
        @parts.delete_if { |key, _| parts.include? key }
      end

      def accept(*parts)
        return if parts.empty?
        parts = parts.map(&:to_sym)
        @parts.keep_if { |key, _| parts.include? key }
      end

      def to_json(*)
        @parts.to_json
      end

      private

      def values_for_parts(parts, view)
        Hash[parts.map { |name, block|
          value = if block.arity == 0
            block.call
          else
            view.attrs[name].tap do |current_value|
              block.call(current_value)
            end
          end

          [name, value]
        }]
      end
    end
  end
end
