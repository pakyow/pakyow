# frozen_string_literal: true

# TODO: rename to significant_nodes.rb

module Pakyow
  module Presenter
    # @api private
    FORM_TAG = "form".freeze
    # @api private
    OPTION_TAG = "option".freeze
    # @api private
    TITLE_TAG = "title".freeze
    # @api private
    BODY_TAG = "body".freeze
    # @api private
    HEAD_TAG = "head".freeze
    # @api private
    TEMPLATE_TAG = "template".freeze

    # @api private
    class SignificantNode
      # Attributes that should be prefixed with +data-+
      #
      DATA_ATTRS = %i(ui).freeze

      # Attributes that will be turned into +StringDoc+ labels
      #
      LABEL_ATTRS = %i(version include exclude).freeze

      def self.node_with_valueless_attribute?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless attribute = node.attributes.first
        return false if !attribute.name || attribute.value
        true
      end

      def self.attributes_instance(element)
        StringAttributes.new(attributes_hash(element))
      end

      def self.attributes_hash(element)
        StringDoc.attributes(element).each_with_object({}) do |attribute, elements|
          attribute_name = attribute.name.to_sym
          attribute_name = :"data-#{attribute_name}" if DATA_ATTRS.include?(attribute_name)
          elements[attribute_name] = attribute.value
        end
      end

      def self.labels_hash(element)
        StringDoc.attributes(element).each_with_object({}) do |attribute, labels|
          attribute_name = attribute.name.to_sym
          next unless LABEL_ATTRS.include?(attribute_name)
          element.unset(attribute.name)
          labels[attribute_name] = attribute.value.to_sym
        end
      end
    end

    # @api private
    class ContainerNode < SignificantNode
      StringDoc.significant :container, self

      CONTAINER_REGEX = /@container\s*([a-zA-Z0-9\-_]*)/.freeze

      def self.significant?(node)
        node.is_a?(Oga::XML::Comment) && node.text.strip.match(CONTAINER_REGEX)
      end

      def self.node(element)
        StringNode.new([element.to_xml, ""], type: :container, name: container_name(element))
      end

      def self.container_name(element)
        match = element.text.strip.match(CONTAINER_REGEX)[1]

        if match.empty?
          :default
        else
          match.to_sym
        end
      end
    end

    # @api private
    class PartialNode < SignificantNode
      StringDoc.significant :partial, self

      PARTIAL_REGEX = /@include\s*([a-zA-Z0-9\-_]*)/.freeze

      def self.significant?(node)
        node.is_a?(Oga::XML::Comment) && node.to_xml.strip.match(PARTIAL_REGEX)
      end

      def self.node(element)
        StringNode.new([element.to_xml, ""], type: :partial, name: partial_name(element))
      end

      def self.partial_name(element)
        element.text.strip.match(PARTIAL_REGEX)[1].to_sym
      end
    end

    # @api private
    class ScopeNode < SignificantNode
      StringDoc.significant :scope, self

      def self.significant?(node)
        return false unless node_with_valueless_attribute?(node)
        return false if node.name == FORM_TAG

        StringDoc.breadth_first(node) do |child|
          return true if PropNode.significant?(child)
        end
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        scope = attributes.keys.first
        attributes.delete(scope)

        StringNode.new(["<#{element.name}", attributes], type: :scope, name: scope, labels: labels)
      end
    end

    # @api private
    class PropNode < SignificantNode
      StringDoc.significant :prop, self

      def self.significant?(node)
        return false unless node_with_valueless_attribute?(node)

        StringDoc.breadth_first(node) do |child|
          return false if significant?(child) || ScopeNode.significant?(child)
        end

        true
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        prop = attributes.keys.first
        attributes.delete(prop)

        StringNode.new(["<#{element.name}", attributes], type: :prop, name: prop, labels: labels)
      end
    end

    # @api private
    class ComponentNode < SignificantNode
      StringDoc.significant :component, self

      def self.significant?(node)
        return false unless node.is_a?(Oga::XML::Element)
        !node.attribute(:ui).nil?
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :component, name: labels[:ui].to_sym, labels: labels)
      end
    end

    # @api private
    class FormNode < SignificantNode
      StringDoc.significant :form, self

      def self.significant?(node)
        node_with_valueless_attribute?(node) && node.name == FORM_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        scope = attributes.keys.first
        attributes.delete(scope)

        StringNode.new(["<#{element.name}", attributes], type: :form, name: scope, labels: labels)
      end
    end

    # @api private
    class OptionNode < SignificantNode
      StringDoc.significant :option, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == OPTION_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :option, name: attributes[:value], labels: labels)
      end
    end

    # @api private
    class TitleNode < SignificantNode
      StringDoc.significant :title, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == TITLE_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :title, name: attributes[:value], labels: labels)
      end
    end

    # @api private
    class BodyNode < SignificantNode
      StringDoc.significant :body, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == BODY_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :body, name: attributes[:value], labels: labels)
      end
    end

    # @api private
    class HeadNode < SignificantNode
      StringDoc.significant :head, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == HEAD_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :head, name: attributes[:value], labels: labels)
      end
    end

    # @api private
    class TemplateNode < SignificantNode
      StringDoc.significant :template, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == TEMPLATE_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :template, name: attributes[:value], labels: labels)
      end
    end
  end
end
