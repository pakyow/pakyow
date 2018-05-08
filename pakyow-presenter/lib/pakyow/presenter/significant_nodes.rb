# frozen_string_literal: true

module Pakyow
  module Presenter
    # @api private
    TITLE_TAG = "title".freeze
    # @api private
    BODY_TAG = "body".freeze
    # @api private
    HEAD_TAG = "head".freeze
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
        node.is_a?(Oga::XML::Element) && node.attribute(:binding)
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
    class ComponentNode < SignificantNode
      StringDoc.significant :component, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:ui)
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
    class TemplateNode < SignificantNode
      StringDoc.significant :template, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == SCRIPT_TAG && node[:type] == "text/template"
      end
    end
  end
end
