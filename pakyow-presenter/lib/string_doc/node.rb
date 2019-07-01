# frozen_string_literal: true

require "pakyow/support/deep_dup"
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

    attr_reader :attributes

    # @api private
    attr_reader :node, :parent, :children, :tag_open_start, :tag_open_end, :tag_close, :transforms, :significance, :labels

    # @api private
    attr_writer :parent

    include Pakyow::Support::Inspectable
    inspectable :@attributes, :@children, :@significance, :@labels

    using Pakyow::Support::DeepDup

    def initialize(tag_open_start = "", attributes = Attributes.new, tag_open_end = "", children = StringDoc.empty, tag_close = "", parent: nil, significance: [], labels: {})
      @tag_open_start, @attributes, @tag_open_end, @children, @tag_close = tag_open_start, attributes, tag_open_end, children, tag_close
      @parent, @labels, @significance = parent, labels, significance
      @transforms = { high: [], default: [], low: [] }
      @pipeline = nil
    end

    # @api private
    def initialize_copy(_)
      super

      @labels = @labels.deep_dup
      @attributes = @attributes.dup
      @children = @children.dup
      @significance = @significance.dup

      @transforms = @transforms.each_with_object({}) { |(key, value), hash|
        hash[key] = value.dup
      }

      @pipeline = nil
    end

    # @api private
    def soft_copy
      instance = self.class.allocate

      instance.instance_variable_set(:@tag_open_start, @tag_open_start)
      instance.instance_variable_set(:@tag_open_end, @tag_open_end)
      instance.instance_variable_set(:@tag_close, @tag_close)
      instance.instance_variable_set(:@parent, @parent)
      instance.instance_variable_set(:@significance, @significance)
      instance.instance_variable_set(:@transforms, @transforms)

      instance.instance_variable_set(:@attributes, @attributes.dup)
      instance.instance_variable_set(:@children, @children.is_a?(StringDoc) ? @children.soft_copy : @children.dup)
      instance.instance_variable_set(:@labels, @labels.deep_dup)
      instance.instance_variable_set(:@pipeline, @pipeline.dup)

      instance
    end

    def freeze(*)
      pipeline
      super
    end

    # @api private
    def empty?
      to_s.strip.empty?
    end

    # Close self with +tag+ and a child.
    #
    # @api private
    def close(tag, child)
      tap do
        @children = StringDoc.from_nodes(child)
        @tag_open_end = tag ? ">" : ""
        @tag_close = (tag && !self.class.self_closing?(tag)) ? "</#{tag}>" : ""
      end
    end

    def next_transform
      pipeline.shift
    end

    def transform(priority: :default, &block)
      @transforms[priority] << block
      @pipeline = nil
    end

    def transforms?
      transforms_itself? || @children.transforms?
    end

    def transforms_itself?
      pipeline.any?
    end

    def significant?(type = nil)
      if type
        @significance.include?(type.to_sym)
      else
        @significance.any?
      end
    end

    def significance?(*types)
      (@significance & types).any?
    end

    # Replaces the current node.
    #
    def replace(replacement)
      @parent.replace_node(self, replacement)
    end

    # Removes the node.
    #
    def remove
      set_label(:removed, true)
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

    # Replaces self's inner html, without making it available for further manipulation.
    #
    def html=(html)
      @children = html.to_s
    end

    # Replaces self's children.
    #
    def replace_children(children)
      @children.replace(children)
    end

    # Returns the node's tagname.
    #
    def tagname
      @tag_open_start.gsub(/[^a-zA-Z0-9]/, "")
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

    # Appends +html+ as a child.
    #
    def append_html(html)
      children.append_html(html)
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

    def render(output = String.new, context: nil)
      if transforms_itself?
        __transform(output, context: context)
      else
        output << tag_open_start

        attributes.each_string do |attribute_string|
          output << attribute_string
        end

        output << tag_open_end

        case children
        when StringDoc
          children.render(output, context: context)
        else
          output << children.to_s
        end

        output << tag_close
      end
    end
    alias :to_html :render
    alias :to_xml :render

    # Returns the node as an xml string, without transforming.
    #
    def to_s
      string_nodes.flatten.map(&:to_s).join
    end

    def ==(other)
      other.is_a?(Node) &&
        @tag_open_start == other.tag_open_start &&
        @attributes == other.attributes &&
        @tag_open_end == other.tag_open_end &&
        @children == other.children &&
        @tag_close == other.tag_close
    end

    def each(descend: false)
      return enum_for(:each, descend: descend) unless block_given?
      yield self
    end

    def each_significant_node(type, descend: false, &block)
      return enum_for(:each_significant_node, type, descend: descend) unless block_given?

      if @children.is_a?(StringDoc)
        @children.each_significant_node(type, descend: descend, &block)
      end
    end

    def each_significant_node_without_descending_into_type(type, descend: false, &block)
      return enum_for(:each_significant_node_without_descending_into_type, type, descend: descend) unless block_given?

      if @children.is_a?(StringDoc)
        @children.each_significant_node_without_descending_into_type(type, descend: descend, &block)
      end
    end

    def each_significant_node_with_name(type, name, descend: false, &block)
      return enum_for(:each_significant_node_with_name, type, name, descend: descend) unless block_given?

      if @children.is_a?(StringDoc)
        @children.each_significant_node_with_name(type, name, descend: descend, &block)
      end
    end

    def find_first_significant_node(type, descend: false)
      if @children.is_a?(StringDoc)
        @children.find_first_significant_node(type, descend: descend)
      else
        nil
      end
    end

    def find_significant_nodes(type, descend: false)
      if @children.is_a?(StringDoc)
        @children.find_significant_nodes(type, descend: descend)
      else
        []
      end
    end

    def find_significant_nodes_with_name(type, name, descend: false)
      if @children.is_a?(StringDoc)
        @children.find_significant_nodes_with_name(type, name, descend: descend)
      else
        []
      end
    end

    private

    def pipeline
      @pipeline ||= @transforms.values.flatten
    end

    def __transform(string, context:)
      node = if frozen?
        soft_copy
      else
        self
      end

      current = node
      while transform = node.next_transform
        return_value = transform.call(node, context, string)

        case return_value
        when NilClass
          return
        when StringDoc
          return_value.render(string, context: context); return
        when Node, MetaNode
          current = return_value
        else
          string << return_value.to_s; return
        end
      end

      # Don't render if the node was removed during the transform.
      #
      if !current.is_a?(Node) || !current.labeled?(:removed)
        current.render(string, context: context)
      end
    end

    def string_nodes
      [@tag_open_start, @attributes, @tag_open_end, @children, @tag_close]
    end
  end
end
