# frozen_string_literal: true

module Pakyow
  module Presenter
    # @api private
    FORM_TAG = "form".freeze
    # @api private
    OPTION_TAG = "option".freeze
    # @api private
    OPTGROUP_TAG = "optgroup".freeze

    # @api private
    class FormNode < SignificantNode
      StringDoc.significant :form, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:binding) && node.name == FORM_TAG
      end
    end

    # @api private
    class OptionNode < SignificantNode
      StringDoc.significant :option, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == OPTION_TAG
      end
    end

    # @api private
    class OptgroupNode < SignificantNode
      StringDoc.significant :optgroup, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == OPTGROUP_TAG
      end
    end
  end
end
