# frozen_string_literal: true

module Pakyow
  module Presenter
    class Form < View
      SELECT_TAG = "select".freeze

      CHECKBOX_TYPE = "checkbox"
      RADIO_TYPE = "radio"
      CHECKED_TYPES = [CHECKBOX_TYPE, RADIO_TYPE]

      private

      def bind_value_to_node(value, node)
        super

        if node.tagname == SELECT_TAG
          select_option_with_value(value, View.from_object(node))
        end

        if CHECKED_TYPES.include?(node.attributes[:type])
          check_or_uncheck_value(value, View.from_object(node))
        end
      end

      def check_or_uncheck_value(value, view)
        view.attributes[:checked] = view.attributes[:value] == value
      end

      def select_option_with_value(value, view)
        view.object.find_significant_nodes(:option).each do |option|
          View.from_object(option).attributes[:selected] = option.attributes[:value] == value
        end
      end
    end
  end
end
