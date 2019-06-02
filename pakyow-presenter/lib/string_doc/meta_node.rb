# frozen_string_literal: true

require "string_doc/meta_attributes"

class StringDoc
  # Lets two or more nodes to be represented as a single node in a doc, then manipulated together.
  #
  class MetaNode
    # @api private
    attr_reader :doc, :transforms, :internal_nodes

    def initialize(nodes)
      nodes.first.parent.replace_node(nodes.first, self)

      nodes[1..-1].each do |node|
        # Remove the node, but don't make it appear to have been removed for transforms.
        #
        node.remove; node.delete_label(:removed)
      end

      nodes.each do |node|
        node.set_label(:__meta_node, true)
      end

      @doc = StringDoc.from_nodes(nodes)
      @transforms = { high: [], default: [], low: [] }

      @internal_nodes = nodes.select { |node|
        !node.is_a?(MetaNode) && node.labeled?(:__meta_node)
      }

      @pipeline = nil
    end

    # @api private
    def initialize_copy(_)
      super

      @doc = @doc.dup

      @transforms = @transforms.each_with_object({}) { |(key, value), hash|
        hash[key] = value.dup
      }

      @internal_nodes = nodes.select { |node|
        !node.is_a?(MetaNode) && node.labeled?(:__meta_node)
      }

      @pipeline = nil
    end

    # @api private
    def soft_copy
      instance = self.class.allocate

      new_doc = @doc.soft_copy
      instance.instance_variable_set(:@doc, new_doc)
      instance.instance_variable_set(:@transforms, @transforms)

      instance.instance_variable_set(:@internal_nodes, new_doc.nodes.select { |node|
        !node.is_a?(MetaNode) && node.labeled?(:__meta_node)
      })

      instance.instance_variable_set(:@pipeline, @pipeline.dup)

      instance
    end

    def freeze(*)
      pipeline
      super
    end

    # @api private
    def parent=(parent)
      @parent = parent
    end

    # @api private
    def nodes
      @doc.nodes
    end

    def children
      internal_nodes.each_with_object(StringDoc.empty) { |node, children|
        case node.children
        when StringDoc
          children.nodes.concat(node.children.nodes)
        end
      }
    end

    def attributes
      MetaAttributes.new(internal_nodes.map(&:attributes))
    end

    def next_transform
      pipeline.shift
    end

    def transform(priority: :default, &block)
      @transforms[priority] << block
      @pipeline = nil
    end

    def transforms?
      transforms_itself? || children.transforms?
    end

    def transforms_itself?
      pipeline.any?
    end

    def significant?(type = nil)
      internal_nodes.any? { |node|
        node.significant?(type)
      }
    end

    def significance?(*types)
      internal_nodes.any? { |node|
        node.significance?(*types)
      }
    end

    def replace(replacement)
      internal_nodes.each do |each_node|
        each_node.replace(replacement)
      end
    end

    def remove
      internal_nodes.each(&:remove)
    end

    def text
      internal_nodes[0].text
    end

    def html
      internal_nodes[0].html
    end

    def html=(html)
      internal_nodes.each do |node|
        node.html = html
      end
    end

    def replace_children(children)
      internal_nodes.each do |node|
        node.replace_children(children)
      end
    end

    def tagname
      internal_nodes[0].tagname
    end

    def clear
      internal_nodes.each(&:clear)
    end

    def after(node)
      @doc.append(node)
    end

    def before(node)
      @doc.prepend(node)
    end

    def append(node)
      internal_nodes.each do |each_node|
        each_node.append(node)
      end
    end

    def append_html(html)
      internal_nodes.each do |each_node|
        each_node.append_html(html)
      end
    end

    def prepend(node)
      internal_nodes.each do |each_node|
        each_node.prepend(node)
      end
    end

    def label(name)
      if node = internal_nodes.first
        node.label(name)
      else
        nil
      end
    end

    def labeled?(name)
      if node = internal_nodes.first
        node.labeled?(name)
      else
        false
      end
    end

    def set_label(name, value)
      internal_nodes.each do |each_node|
        each_node.set_label(name, value)
      end
    end

    def delete_label(name)
      internal_nodes.each do |each_node|
        each_node.delete_label(name)
      end
    end

    def each(descend: false, &block)
      internal_nodes.each do |node|
        node.each(descend: descend, &block)
      end
    end

    def each_significant_node(type, descend: false, &block)
      return enum_for(:each_significant_node, type, descend: descend) unless block_given?

      internal_nodes.each do |node|
        node.each_significant_node(type, descend: descend, &block)
      end
    end

    def each_significant_node_without_descending_into_type(type, descend: false, &block)
      return enum_for(:each_significant_node_without_descending_into_type, type, descend: descend) unless block_given?

      internal_nodes.each do |node|
        node.each_significant_node_without_descending_into_type(type, descend: descend, &block)
      end
    end

    def each_significant_node_with_name(type, name, descend: false, &block)
      return enum_for(:each_significant_node_with_name, type, name, descend: descend) unless block_given?

      internal_nodes.each do |node|
        node.each_significant_node_with_name(type, name, descend: descend, &block)
      end
    end

    def find_first_significant_node(type, descend: false)
      internal_nodes.each do |node|
        if found = node.find_first_significant_node(type, descend: descend)
          return found
        end
      end

      nil
    end

    def find_significant_nodes(type, descend: false)
      internal_nodes.each_with_object([]) { |node, collected|
        collected.concat(node.find_significant_nodes(type, descend: descend))
      }
    end

    def find_significant_nodes_with_name(type, name, descend: false)
      internal_nodes.each_with_object([]) { |node, collected|
        collected.concat(node.find_significant_nodes_with_name(type, name, descend: descend))
      }
    end

    # Converts the node to an xml string.
    #
    def render(output = String.new, context: nil)
      if transforms_itself?
        __transform(output, context: context)
      else
        nodes.each do |each_node|
          each_node.render(output, context: context)
        end
      end
    end
    alias :to_html :render
    alias :to_xml :render

    # Returns the node as an xml string, without transforming.
    #
    def to_s
      nodes.each_with_object(String.new) do |node, string|
        string << node.to_s
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
  end
end
