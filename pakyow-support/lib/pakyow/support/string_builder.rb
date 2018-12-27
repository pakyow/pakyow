# frozen_string_literal: true

module Pakyow
  module Support
    # Builds a string from a template.
    #
    class StringBuilder
      PATTERN = /{([^}]*)}/

      def initialize(template, &block)
        @template, @block = template, block
      end

      def build(**values)
        @template.dup.tap do |working_template|
          working_template.scan(PATTERN).each do |match|
            value = if match[0].include?(".")
              object, property = match[0].split(".").map(&:to_sym)
              if object_value = get_value(object, values)
                ensure_real_value(object_value)[property]
              end
            else
              get_value(match[0].to_sym, values)
            end

            working_template.gsub!("{#{match[0]}}", value.to_s)
          end
        end
      end

      private

      def get_value(name, values)
        if @block
          @block.call(name)
        elsif values.key?(name)
          values[name]
        else
          nil
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
