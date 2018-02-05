# frozen_string_literal: true

# TODO: rename to significant_nodes.rb

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
    SCRIPT_TAG = "script".freeze

    # @api private
    class SignificantNode
      # Attributes that should be prefixed with +data-+
      #
      DATA_ATTRS = %i(ui).freeze

      # Attributes that will be turned into +StringDoc+ labels
      #
      LABEL_ATTRS = %i(ui version include exclude).freeze

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
    class PrototypeNode < SignificantNode
      StringDoc.significant :prototype, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:prototype)
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :prototype, labels: labels)
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
          Page::DEFAULT_CONTAINER
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
    class BindingNode < SignificantNode
      StringDoc.significant :binding, self

      def self.significant?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false if !node.attribute(:binding)
        return false if node.name == FORM_TAG
        true
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        binding = attributes[:binding].to_sym
        attributes.delete(:binding)
        attributes[:"data-b"] = binding

        StringNode.new(["<#{element.name}", attributes], type: :binding, name: binding, labels: labels)
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
        component_name = labels[:ui].to_sym
        attributes[:"data-ui"] = component_name
        StringNode.new(["<#{element.name}", attributes], type: :component, name: component_name, labels: labels)
      end
    end

    # @api private
    class FormNode < SignificantNode
      StringDoc.significant :form, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.attribute(:binding) && node.name == FORM_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        binding = attributes[:binding].to_sym
        attributes.delete(:binding)
        attributes[:"data-b"] = binding

        StringNode.new(["<#{element.name}", attributes], type: :form, name: binding, labels: labels)
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
    class OptgroupNode < SignificantNode
      StringDoc.significant :optgroup, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == OPTGROUP_TAG
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name}", attributes], type: :optgroup, labels: labels)
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
        node.is_a?(Oga::XML::Element) && node.name == SCRIPT_TAG && node[:type] == "text/template"
      end

      def self.node(element)
        labels = labels_hash(element)
        attributes = attributes_instance(element)
        StringNode.new(["<script", attributes], type: :template, name: attributes[:value], labels: labels)
      end
    end
  end
end
