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
          select_option_with_value(value, node)
        end

        if CHECKED_TYPES.include?(node.attributes[:type])
          check_or_uncheck_value(value, node)
        end
      end

      def check_or_uncheck_value(value, node)
        if node.attributes[:value] == value
          node.attributes[:checked] = "checked"
        else
          node.attributes[:checked] = nil
        end
      end

      def select_option_with_value(value, node)
        if option = node.find_significant_nodes_with_name(:option, value.to_s)[0]
          option.attributes[:selected] = "selected"
        end
      end
    end
  end
end
