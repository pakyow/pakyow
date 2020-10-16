# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"

require_relative "../view"

module Pakyow
  module Presenter
    module Views
      class Form < View
        using Support::Refinements::Array::Ensurable

        INPUT_TAG = "input"
        SELECT_TAG = "select"
        TEXTAREA_TAG = "textarea"

        FIELD_TAGS = [
          INPUT_TAG,
          SELECT_TAG,
          TEXTAREA_TAG
        ].freeze

        CHECKBOX_TYPE = "checkbox"
        RADIO_TYPE = "radio"

        CHECKED_TYPES = [
          CHECKBOX_TYPE, RADIO_TYPE
        ].freeze

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
          view.attributes[:checked] = if view.attributes[:type] == "checkbox"
            # There could be multiple values checked, so check for inclusion.
            #
            Array.ensure(value).map(&:to_s).include?(view.attributes[:value])
          else
            view.attributes[:value] == value.to_s
          end
        end

        def select_option_with_value(value, view)
          view.object.each_significant_node(:option) do |option|
            View.from_object(option).attributes[:selected] = option.attributes[:value] == value
          end
        end
      end
    end
  end
end
