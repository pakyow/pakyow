# frozen_string_literal: true

require "forwardable"

require "pakyow/support/inspectable"

class StringDoc
  # String-based XML node.
  #
  class Node
    class << self
      SELF_CLOSING = %w[area base basefont br hr input img link meta].freeze
      FORM_INPUTS  = %w[input select textarea button].freeze
      VALUELESS    = %w[select].freeze

      # Returns true if +tag+ is self-closing.
      #
      def self_closing?(tag)
        SELF_CLOSING.include?(tag)
      end

      # Returns true if +tag+ is a form input.
      #
      def form_input?(tag)
        FORM_INPUTS.include?(tag)
      end

      # Returns true if +tag+ does not contain a value.
      #
      def without_value?(tag)
        VALUELESS.include?(tag)
      end
    end

    attr_reader :node, :parent, :children, :attributes

    # @api private
    attr_writer :parent

    extend Forwardable
    def_delegators :children, :find_significant_nodes, :find_significant_nodes_with_name, :find_significant_nodes_without_descending

    include Pakyow::Support::Inspectable
    inspectable :attributes, :children, :significance, :labels

    def initialize(node, parent: nil, significance: [], labels: {})
      @node, @parent, @labels = node, parent, labels
      @significance = significance
      @attributes = @node[1]
      @children = StringDoc.empty
    end

    # @api private
    def initialize_copy(_)
      super

      @significance = @significance.dup
      @attributes = @attributes.dup
      @children = @children.dup

      @node = @node.dup
      @node[1] = @attributes
      @node[3] = @children

      @labels = @labels.dup
    end

    def significant?(type = nil)
      if type
        @significance.include?(type.to_sym)
      else
        @significance.any?
      end
    end

    # Close self with +tag+ and a child.
    #
    def close(tag, child)
      tap do
        @children = StringDoc.from_nodes(child)

        @node << (tag ? ">" : "")
        @node << @children
        @node << ((tag && !self.class.self_closing?(tag)) ? "</#{tag}>" : "")
      end
    end

    # Returns an array containing +self+ and any child nodes.
    #
    def with_children
      [self].tap do |self_with_children|
        if children
          self_with_children.concat(child_nodes)
        end
      end
    end

    # Replaces the current node.
    #
    def replace(replacement)
      @parent.replace_node(self, replacement)
    end

    # Removes the node.
    #
    def remove
      @parent.remove_node(self)
    end

    REGEX_TAGS = /<[^>]*>/

    # Returns the text of this node and all children, joined together.
    #
    def text
      html.gsub(REGEX_TAGS, "")
    end

    # Returns the html contained within self.
    #
    def html
      children.to_s
    end

    # Replaces self's inner html.
    #
    def html=(html)
      children.replace(html)
    end

    # Returns the node's tagname.
    #
    def tagname
      @node[0].gsub(/[^a-zA-Z]/, "")
    end

    # Removes all children.
    #
    def clear
      children.clear
    end

    # Inserts +node+ after +self+.
    #
    def after(node)
      @parent.insert_after(node, self)
    end

    # Inserts +node+ before +self+.
    #
    def before(node)
      @parent.insert_before(node, self)
    end

    # Appends +node+ as a child.
    #
    def append(node)
      children.append(node)
    end

    # Prepends +node+ as a child.
    #
    def prepend(node)
      children.prepend(node)
    end

    # Returns the value for label with +name+.
    #
    def label(name)
      @labels[name.to_sym]
    end

    # Returns true if label exists with +name+.
    #
    def labeled?(name)
      @labels.key?(name.to_sym)
    end

    # Sets the label with +name+ and +value+.
    #
    def set_label(name, value)
      @labels[name.to_sym] = value
    end

    # Delete the label with +name+.
    #
    def delete_label(name)
      @labels.delete(name.to_sym)
    end

    # Converts the node to an xml string.
    #
    def to_xml
      @node.flatten.map(&:to_s).join
    end
    alias :to_html :to_xml
    alias :to_s :to_xml

    def ==(other)
      return false unless other.is_a?(Node)

      @node.each_with_index do |part, index|
        return false unless other.node[index] == part
      end

      true
    end

    # @api private
    def string_nodes
      [@node[0], @node[1], @node[2], @node[3]&.string_nodes, @node[4]]
    end

    protected

    def child_nodes
      children.nodes.map(&:with_children).to_a.flatten
    end
  end
end
