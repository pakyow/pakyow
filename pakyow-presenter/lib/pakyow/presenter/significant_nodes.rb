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
    TITLE_TAG = "title".freeze
    # @api private
    BODY_TAG = "body".freeze
    # @api private
    HEAD_TAG = "head".freeze
    # @api private
    HTML_TAG = "html".freeze
    # @api private
    SCRIPT_TAG = "script".freeze

    # @api private
    class SignificantNode
      def self.within_binding?(node)
        if BindingNode.significant?(node)
          true
        elsif !node.is_a?(Oga::XML::Document)
          within_binding?(node.parent)
        else
          false
        end
      end

      def self.binding_within?(node)
        node.children.each do |child|
          if BindingNode.significant?(child)
            return true
          else
            binding_within?(child)
          end
        end

        false
      end
    end

    # @api private
    class PrototypeNode < SignificantNode
      StringDoc.significant :prototype, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:prototype)
      end
    end

    # @api private
    class EndpointNode < SignificantNode
      StringDoc.significant :endpoint, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:endpoint)
      end
    end

    # @api private
    class EndpointActionNode < SignificantNode
      StringDoc.significant :endpoint_action, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:"endpoint-action")
      end
    end

    # @api private
    class ContainerNode < SignificantNode
      StringDoc.significant :container, self

      CONTAINER_REGEX = /@container\s*([a-zA-Z0-9\-_]*)/.freeze

      def self.significant?(node)
        node.is_a?(Oga::XML::Comment) && node.text.strip.match(CONTAINER_REGEX)
      end
    end

    # @api private
    class PartialNode < SignificantNode
      StringDoc.significant :partial, self

      PARTIAL_REGEX = /@include\s*([a-zA-Z0-9\-_]*)/.freeze

      def self.significant?(node)
        node.is_a?(Oga::XML::Comment) && node.to_xml.strip.match(PARTIAL_REGEX)
      end
    end

    # @api private
    class BindingNode < SignificantNode
      StringDoc.significant :binding, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:binding) && node.name != FORM_TAG
      end
    end

    # @api private
    class WithinBindingNode < SignificantNode
      StringDoc.significant :within_binding, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && within_binding?(node)
      end
    end

    # @api private
    class BindingWithinNode < SignificantNode
      StringDoc.significant :binding_within, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && binding_within?(node)
      end
    end

    # @api private
    class ComponentNode < SignificantNode
      StringDoc.significant :component, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:ui)
      end
    end

    # @api private
    class ModeNode < SignificantNode
      StringDoc.significant :mode, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:mode)
      end
    end

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

    # @api private
    class TitleNode < SignificantNode
      StringDoc.significant :title, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == TITLE_TAG
      end
    end

    # @api private
    class BodyNode < SignificantNode
      StringDoc.significant :body, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == BODY_TAG
      end
    end

    # @api private
    class HeadNode < SignificantNode
      StringDoc.significant :head, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == HEAD_TAG
      end
    end

    # @api private
    class HTMLNode < SignificantNode
      StringDoc.significant :html, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == HTML_TAG
      end
    end

    # @api private
    class TemplateNode < SignificantNode
      StringDoc.significant :template, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == SCRIPT_TAG && node[:type] == "text/template"
      end
    end
  end
end
