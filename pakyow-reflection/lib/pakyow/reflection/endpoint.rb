# frozen_string_literal: true

module Pakyow
  module Reflection
    # @api private
    class Exposure
      attr_reader :scope, :node, :binding, :dataset, :parent, :children

      def initialize(scope:, node:, binding:, dataset: nil, parent: nil)
        @scope = scope
        @node = node
        @binding = binding
        @dataset = parse_dataset(dataset) if dataset
        @parent = parent
        @children = []

        if parent
          parent.children << self
        end
      end

      def cleanup
        @node = nil
      end

      private

      def parse_dataset(dataset)
        options = {}

        dataset.to_s.split(";").each do |dataset_part|
          key, value = dataset_part.split(":", 2).map(&:to_s).map(&:strip)

          value = if value.include?(",") || value.include?("(")
            value.split(",").map { |value_part|
              parse_value_part(value_part)
            }
          else
            parse_value_part(value)
          end

          options[key.to_sym] = value
        end

        options
      end

      def parse_value_part(value_part)
        value_part = value_part.strip

        if value_part.include?("(")
          value_part.split("(").map { |sub_value_part|
            sub_value_part.strip.gsub(")", "")
          }
        else
          value_part
        end
      end
    end

    # @api private
    class Endpoint
      attr_reader :view_path, :options, :exposures

      def initialize(view_path, options: {})
        @view_path = view_path
        @options = options || {}
        @exposures = []
      end

      def type
        @options[:type] || :member
      end

      def add_exposure(exposure)
        @exposures << exposure
      end

      def cleanup
        @exposures.each(&:cleanup)
      end
    end
  end
end
