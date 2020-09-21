# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/hookable"
require "pakyow/support/makeable"

module Pakyow
  module Presenter
    # Reusable functionality for a view component.
    #
    class Component
      include Support::Makeable

      extend Support::ClassState
      class_state :__presenter_class, default: Presenter, inheritable: true
      class_state :inherit_values, default: false

      include Support::Hookable
      events :render

      attr_reader :connection

      def initialize(connection:, config: {})
        @connection, @config = connection, config
      end

      def perform
        # intentionally empty
      end

      class << self
        def presenter(&block)
          @__presenter_class = Class.new(@__presenter_class) {
            class_eval(&block)
          }

          const_set(:Presenter, @__presenter_class)
        end

        def parse(string)
          component, config_string = string.split("(")

          {
            name: component.strip.to_sym,
            config: parse_config(config_string)
          }
        end

        def parse_config(string)
          if string
            string.strip[0..-2].split(",").each_with_object({}) { |config_string_part, values|
              key, value = config_string_part.split(":")

              value = if value
                value.strip
              else
                true
              end

              values[key.strip.to_sym] = value
            }
          else
            {}
          end
        end
      end
    end
  end
end
