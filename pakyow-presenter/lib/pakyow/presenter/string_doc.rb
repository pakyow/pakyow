# frozen_string_literal: true

require "pakyow/support/silenceable"

module Pakyow
  module Presenter
    # String-based XML document optimized for fast manipulation and rendering.
    #
    # In Pakyow, we rarely care about every node in a document. Instead, only significant nodes and
    # immediate children are available for manipulation. StringDoc provides "just enough" for our
    # purposes. A StringDoc is represented as a multi- dimensional array of strings, making
    # rendering essentially a +flatten.join+.
    #
    # Because less work is performed during render, StringDoc is consistently faster than rendering
    # a document using Nokigiri or Oga. One obvious tradeoff is that parsing is much slower (we use
    # Oga to parse the XML, then convert it into a StringDoc). This is an acceptable tradeoff
    # because we only pay the parsing cost once (when the Pakyow application boots).
    #
    # All that to say, StringDoc is a tool that is very specialized to Pakyow's use-case. Use it
    # only when a longer parse time is acceptable and you only care about a handful of identifiable
    # nodes in a document.
    #
    class StringDoc
      class << self
        # Creates an empty doc.
        #
        def empty
          allocate.tap do |doc|
            doc.instance_variable_set(:@nodes, [])
          end
        end

        # Registers a significant node with a name and an object to handle parsing.
        #
        def significant(name, object)
          significant_types[name] = object
        end

        # Creates a +StringDoc+ from an array of +StringNode+ objects.
        #
        def from_nodes(nodes)
          allocate.tap do |instance|
            instance.instance_variable_set(:@nodes, nodes)

            nodes.each do |node|
              node.parent = instance
            end
          end
        end

        # Yields nodes from an oga document, breadth-first.
        #
        def breadth_first(doc)
          queue = [doc]

          until queue.empty?
            element = queue.shift

            if element == doc
              queue.concat(element.children.to_a); next
            end

            yield element
          end
        end

        # Returns attributes for an oga element.
        #
        def attributes(element)
          if element.is_a?(Oga::XML::Element)
            element.attributes
          else
            []
          end
        end

        # Builds a string-based representation of attributes for an oga element.
        #
        def attributes_string(element)
          attributes(element).each_with_object(String.new) do |attribute, string|
            string << " #{attribute.name}=\"#{attribute.value}\""
          end
        end

        # Determines the significance of +element+.
        #
        def find_significance(element)
          significant_types.each_with_object([]) do |(key, object), significance|
            if object.significant?(element)
              significance << key
            end
          end
        end

        # Returns true if the given Oga element contains a child node that is significant.
        #
        def contains_significant_child?(element)
          element.children.each do |child|
            return true if find_significance(child).any?
            return true if contains_significant_child?(child)
          end

          false
        end

        # @api private
        def significant_types
          @significant_types ||= {}
        end

        # @api private
        def nodes_from_doc_or_string(doc_node_or_string)
          if doc_node_or_string.is_a?(StringDoc)
            doc_node_or_string.nodes
          elsif doc_node_or_string.is_a?(StringNode)
            [doc_node_or_string]
          else
            StringDoc.new(doc_node_or_string.to_s).nodes
          end
        end
      end

      include Support::Silenceable

      # Array of +StringNode+ objects.
      #
      attr_reader :nodes

      # Creates a +StringDoc+ from an html string.
      #
      def initialize(html)
        @nodes = parse(Oga.parse_html(html))
      end

      # @api private
      def initialize_copy(_)
        super

        @nodes = @nodes.map { |node|
          node.dup.tap do |duped_node|
            duped_node.parent = self
          end
        }
      end

      # Returns nodes matching the significant type.
      #
      def find_significant_nodes(type)
        @nodes.each_with_object([]) { |node, matches|
          if node.significant?(type)
            matches << node
          end

          matches.concat(node.children.find_significant_nodes(type))
        }
      end

      # Returns nodes matching the significant type, without descending into
      # nodes that are of that type.
      #
      def find_significant_nodes_without_descending(type)
        @nodes.flat_map { |node|
          if node.significant?(type)
            node
          else
            node.children.find_significant_nodes_without_descending(type)
          end
        }
      end

      # Returns nodes matching the significant type and name.
      #
      # @see find_significant_nodes
      #
      def find_significant_nodes_with_name(type, name)
        find_significant_nodes(type).select { |node|
          node.label(type) == name
        }
      end

      # Returns nodes matching the significant type and name, without descending
      # into nodes that are of that type.
      #
      # @see find_significant_nodes
      #
      def find_significant_nodes_with_name_without_descending(type, name)
        find_significant_nodes_without_descending(type).select { |node|
          node.label(type) == name
        }
      end

      # Clears all nodes.
      #
      def clear
        tap do
          @nodes.clear
        end
      end
      alias remove clear

      # Replaces the current document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def replace(doc_or_string)
        tap do
          @nodes = self.class.nodes_from_doc_or_string(doc_or_string)
        end
      end

      # Appends to this document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def append(doc_or_string)
        tap do
          @nodes.concat(self.class.nodes_from_doc_or_string(doc_or_string))
        end
      end

      # Prepends to this document.
      #
      # Accepts a +StringDoc+ or XML +String+.
      #
      def prepend(doc_or_string)
        tap do
          @nodes.unshift(*self.class.nodes_from_doc_or_string(doc_or_string))
        end
      end

      # Inserts a node after another node contained in this document.
      #
      def insert_after(node_to_insert, after_node)
        tap do
          if after_node_index = @nodes.index(after_node)
            @nodes.insert(after_node_index + 1, *self.class.nodes_from_doc_or_string(node_to_insert))
          end
        end
      end

      # Inserts a node before another node contained in this document.
      #
      def insert_before(node_to_insert, before_node)
        tap do
          if before_node_index = @nodes.index(before_node)
            @nodes.insert(before_node_index, *self.class.nodes_from_doc_or_string(node_to_insert))
          end
        end
      end

      # Removes a node from the document.
      #
      def remove_node(node_to_delete)
        tap do
          @nodes.delete_if { |node|
            node.object_id == node_to_delete.object_id
          }
        end
      end

      # Replaces a node from the document.
      #
      def replace_node(node_to_replace, replacement_node)
        tap do
          if replace_node_index = @nodes.index(node_to_replace)
            nodes_to_insert = self.class.nodes_from_doc_or_string(replacement_node).map { |node|
              node.instance_variable_set(:@parent, self); node
            }
            @nodes.insert(replace_node_index + 1, *nodes_to_insert)
            @nodes.delete_at(replace_node_index)
          end
        end
      end

      # Converts the document to an xml string.
      #
      def to_xml
        render
      end
      alias :to_html :to_xml
      alias :to_s :to_xml

      def ==(other)
        other.is_a?(StringDoc) && @nodes == other.nodes
      end

      # @api private
      def string_nodes
        @nodes.map(&:string_nodes)
      end

      private

      def render
        # @nodes.flatten.reject(&:empty?).map(&:to_s).join

        # we save several (hundreds) of calls to `flatten` by pulling in each node and dealing with
        # them together instead of calling `to_s` on each
        arr = string_nodes
        arr.flatten!
        arr.compact!
        arr.map!(&:to_s)
        arr.join
      end

      # Parses an Oga document into an array of +StringNode+ objects.
      #
      def parse(doc)
        nodes = []

        unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
          nodes << StringNode.new(["<!DOCTYPE html>", StringAttributes.new, []])
        end

        self.class.breadth_first(doc) do |element|
          significance = self.class.find_significance(element)

          unless significance.any? || self.class.contains_significant_child?(element)
            # Nothing inside of the node is significant, so collapse it to a single node.
            nodes << StringNode.new([element.to_xml, StringAttributes.new, []]); next
          end

          node = if significance.any?
            build_significant_node(element, significance)
          elsif element.is_a?(Oga::XML::Text) || element.is_a?(Oga::XML::Comment)
            StringNode.new([element.to_xml, StringAttributes.new, []])
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

      # Attributes that should be prefixed with +data-+
      #
      DATA_ATTRS = %i(ui binding endpoint endpoint-action version config).freeze

      # Attributes that will be turned into +StringDoc+ labels
      #
      LABEL_ATTRS = %i(ui mode version include exclude endpoint endpoint-action prototype binding).freeze

      LABEL_MAPPING = {
        ui: :component
      }

      # Attributes that should be deleted from the view
      #
      DELETED_ATTRS = %i(include exclude prototype).freeze

      ATTR_MAPPING = {
        binding: :b,
        endpoint: :e,
        "endpoint-action": :"e-a",
        version: :v
      }

      def attributes_hash(element)
        StringDoc.attributes(element).each_with_object({}) { |attribute, elements|
          elements[attribute.name.to_sym] = attribute.value
        }
      end

      def labels_hash(element)
        StringDoc.attributes(element).dup.each_with_object({}) { |attribute, labels|
          attribute_name = attribute.name.to_sym

          if LABEL_ATTRS.include?(attribute_name)
            labels[LABEL_MAPPING.fetch(attribute_name, attribute_name)] = attribute.value.to_s.to_sym
          end
        }
      end

      def build_significant_node(element, significance)
        if element.is_a?(Oga::XML::Element)
          attributes = attributes_hash(element).each_with_object({}) { |(key, value), remapped_attributes|
            unless DELETED_ATTRS.include?(key)
              remapped_key = ATTR_MAPPING.fetch(key, key)

              if DATA_ATTRS.include?(key)
                remapped_key = :"data-#{remapped_key}"
              end

              remapped_attributes[remapped_key] = value || ""
            end
          }

          labels = labels_hash(element)

          if labels.include?(:binding)
            find_channel_for_binding!(element, attributes, labels)
          end

          StringNode.new(["<#{element.name}", StringAttributes.new(attributes)], significance: significance, labels: labels, parent: self)
        else
          name = element.text.strip.match(/@[^\s]*\s*([a-zA-Z0-9\-_]*)/)[1]
          labels = significance.each_with_object({}) { |significant_type, labels_hash|
            # FIXME: remove this special case logic
            labels_hash[significant_type] = if name.empty? && significant_type == :container
              Page::DEFAULT_CONTAINER
            else
              name.to_sym
            end
          }

          StringNode.new([element.to_xml, ""], significance: significance, parent: self, labels: labels)
        end
      end

      def find_channel_for_binding!(element, attributes, labels)
        channel = semantic_channel_for_element(element)

        binding_parts = labels[:binding].to_s.split(":").map(&:to_sym)
        labels[:binding] = binding_parts[0]
        attributes[:"data-b"] = binding_parts[0]

        channel.concat(binding_parts[1..-1])
        labels[:channel] = channel

        combined_channel = channel.join(":")
        labels[:combined_channel] = combined_channel

        unless channel.empty?
          attributes[:"data-c"] = combined_channel
        end
      end

      SEMANTIC_TAGS = %w(
        article
        aside
        details
        footer
        form
        header
        main
        nav
        section
        summary
      ).freeze

      def semantic_channel_for_element(element, channel = [])
        if element.parent.is_a?(Oga::XML::Element)
          semantic_channel_for_element(element.parent, channel)
        end

        if SEMANTIC_TAGS.include?(element.name)
          channel << element.name.to_sym
        end

        channel
      end
    end
  end
end
