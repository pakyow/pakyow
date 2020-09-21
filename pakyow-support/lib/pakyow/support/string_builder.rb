# frozen_string_literal: true

require_relative "safe_string"

module Pakyow
  module Support
    # Builds a string from a template.
    #
    class StringBuilder
      include SafeStringHelpers

      PATTERN = /{([^}]*)}/

      def initialize(template, html_safe: false, &block)
        @template, @html_safe, @block = template.to_s, html_safe, block
      end

      def build(**values)
        @template.dup.tap do |working_template|
          working_template.scan(PATTERN).each do |match|
            value = if match[0].include?(".")
              object, property = match[0].split(".").map(&:to_sym)
              if (object_value = get_value(object, values))
                ensure_real_value(object_value)[property]
              end
            else
              get_value(match[0].to_sym, values)
            end

            value = if @html_safe
              ensure_html_safety(value)
            else
              value.to_s
            end

            working_template.gsub!("{#{match[0]}}", value)
          end
        end
      end

      private

      def get_value(name, values)
        if @block
          @block.call(name)
        elsif values.key?(name)
          values[name]
        end
      end

      def ensure_real_value(object_value)
        if defined?(Pakyow::Data::Proxy) && object_value.is_a?(Pakyow::Data::Proxy)
          object_value.one
        else
          object_value
        end
      end
    end
  end
end
