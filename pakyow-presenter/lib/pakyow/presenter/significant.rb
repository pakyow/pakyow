module Pakyow
  module Presenter
    FORM_TAG = "form".freeze
    OPTION_TAG = "option".freeze

    class SignificantNode
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
          elements[attribute.name.to_sym] = Attributes.typed_value_for_attribute_with_name(attribute.value, attribute.name)
        end
      end
    end

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
        attributes = attributes_instance(element)
        scope = attributes.keys.first
        attributes[:"data-scope"] = scope
        attributes.delete(scope)

        StringNode.new(["<#{element.name} ", attributes], type: :scope, name: scope)
      end
    end

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
        attributes = attributes_instance(element)
        prop = attributes.keys.first
        attributes[:"data-prop"] = prop
        attributes.delete(prop)

        StringNode.new(["<#{element.name} ", attributes], type: :prop, name: prop)
      end
    end

    class ComponentNode < SignificantNode
      StringDoc.significant :component, self

      def self.significant?(node)
        return false unless node.is_a?(Oga::XML::Element)
        !node.attribute(:"data-ui").nil?
      end

      def self.node(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name} ", attributes], type: :component, name: attributes[:"data-ui"].to_sym)
      end
    end

    class FormNode < SignificantNode
      StringDoc.significant :form, self

      def self.significant?(node)
        node_with_valueless_attribute?(node) && node.name == FORM_TAG
      end

      def self.node(element)
        attributes = attributes_instance(element)
        scope = attributes.keys.first
        attributes[:"data-scope"] = scope
        attributes.delete(scope)

        StringNode.new(["<#{element.name} ", attributes], type: :form, name: scope)
      end
    end

    class OptionNode < SignificantNode
      StringDoc.significant :option, self

      def self.significant?(node)
        node.is_a?(Oga::XML::Element) && node.name == OPTION_TAG
      end

      def self.node(element)
        attributes = attributes_instance(element)
        StringNode.new(["<#{element.name} ", attributes], type: :option, name: attributes[:value])
      end
    end
  end
end
