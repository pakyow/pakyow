require "pakyow/support/silenceable"
require "pakyow/support/inspectable"

module Pakyow
  module Presenter
    # @api private
    class StringDoc
      class << self
        def significant(name, object)
          significant_types[name] = object
        end

        def significant_types
          @significant_types ||= {}
        end

        def from_nodes(nodes)
          instance = allocate
          instance.instance_variable_set(:@nodes, nodes)
          instance
        end

        def ensure(object)
          return object if object.is_a?(StringDoc)
          StringDoc.new(object)
        end

        def breadth_first(doc)
          queue = [doc]
          until queue.empty?
            yield queue.shift, queue
          end
        end

        def attributes(node)
          if node.is_a?(Oga::XML::Element)
            node.attributes
          else
            []
          end
        end

        def attributes_string(node)
          attributes(node).each_with_object("") do |attribute, string|
            string << " #{attribute.name}=\"#{attribute.value}\""
          end
        end
      end

      include Support::Silenceable
      include Support::Inspectable

      inspectable :nodes

      attr_reader :nodes, :significant_nodes

      def initialize(html)
        @nodes = parse(Oga.parse_html(html))
        @significant = {}
      end

      def initialize_copy(original)
        super

        @nodes = @nodes.map(&:dup).each do |node|
          node.instance_variable_set(:@parent, self)
        end

        @significant = {}
      end

      def find_significant_nodes(type)
        type = type.to_sym
        @significant[type] ||= nodes.map(&:with_children).flatten.select { |node|
          node.type == type
        }
      end

      def find_significant_nodes_with_name(type, name)
        name = name.to_sym
        find_significant_nodes(type).select { |node|
          node.name == name
        }
      end

      def clear
        nodes.clear
      end

      def append(doc)
        children.concat(StringDoc.ensure(doc).nodes)
      end

      def prepend(doc)
        children.unshift(*StringDoc.ensure(doc).nodes)
      end

      def after(doc)
        nodes.concat(StringDoc.ensure(doc).nodes)
      end

      def before(doc)
        nodes.unshift(*StringDoc.ensure(doc).nodes)
      end

      def replace(doc)
        @nodes = StringDoc.ensure(doc).nodes
      end

      def insert_after(node_to_insert, after_node)
        @nodes.insert(@nodes.index(after_node) + 1, node_to_insert)
      end

      def to_html
        render
      end

      alias :to_s :to_html

      def ==(comparison)
        comparison.is_a?(StringDoc) && nodes == comparison.nodes
      end

      private

      def render(nodes = @nodes)
        nodes.flatten.reject(&:empty?).map(&:to_s).join
      end

      def parse(doc)
        nodes = []

        unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
          nodes << StringNode.new(["<!DOCTYPE html>", "", []])
        end

        self.class.breadth_first(doc) do |element, queue|
          if element == doc
            queue.concat(element.children.to_a); next
          end

          # TODO: why do we do this? optimization?
          children = element.children.reject {|n| n.is_a?(Oga::XML::Text)}

          significant_object = significant(element)

          # this is an optimization we can make because we don't care about this element and
          # we know that nothing inside of it is significant, so we can just collapse it
          if !nodes.empty? && children.empty? && !significant_object
            nodes << StringNode.new([element.to_xml, "", []]); next
          end

          node = if significant_object
                   build_significant_node(element, significant_object)
                 elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
                   StringNode.new([element.to_xml, "", []])
                 else
                   StringNode.new(["<#{element.name}#{self.class.attributes_string(element)}", ""])
                 end

          if element.is_a?(Oga::XML::Element)
            node.close(element.name, parse(element))
          end

          nodes << node
        end

        nodes
      end

      def significant(node)
        self.class.significant_types.values.each do |object|
          return object if object.significant?(node)
        end

        false
      end

      def build_significant_node(element, object)
        node = object.node(element)
        node.parent = self
        node
      end
    end
  end
end
