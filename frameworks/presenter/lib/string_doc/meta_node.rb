# frozen_string_literal: true

require_relative "meta_attributes"

class StringDoc
  # Lets two or more nodes to be represented as a single node in a doc, then manipulated together.
  #
  # @api private
  class MetaNode
    # @api private
    attr_reader :doc, :transforms, :internal_nodes

    def initialize(nodes)
      # Reparent nodes that belong to the same parent.
      #
      nodes.group_by { |node| node.parent }.each_pair do |parent, children|
        # If the children already belong to a meta node doc, don't reparent them again.
        #
        unless children.first.labeled?(:__meta_node)
          parent.replace_node(children.first, self)
        end

        children[1..].each do |node|
          # Remove the node, but don't make it appear to have been removed for transforms.
          #
          node.remove(false, false)
        end
      end

      nodes.each do |node|
        node.set_label(:__meta_node, true)
      end

      @doc = StringDoc.from_nodes(nodes)
      @transforms = {high: [], default: [], low: []}

      @internal_nodes = nodes.dup

      @pipeline = nil
    end

    # @api private
    def initialize_copy(_)
      super

      nodes, internal_nodes = [], []
      @doc.nodes.each do |current_node|
        duped_node = current_node.dup
        nodes << duped_node

        if @internal_nodes.any? { |current_internal_node| current_internal_node.equal?(current_node) }
          internal_nodes << duped_node
        end
      end

      @doc = StringDoc.from_nodes(nodes)

      @transforms = @transforms.each_with_object({}) { |(key, value), hash|
        hash[key] = value.dup
      }

      @internal_nodes = internal_nodes

      @pipeline = nil
    end

    # @api private
    def soft_copy
      instance = self.class.allocate

      nodes, internal_nodes = [], []
      @doc.nodes.each do |current_node|
        duped_node = current_node.soft_copy
        nodes << duped_node

        if @internal_nodes.any? { |current_internal_node| current_internal_node.equal?(current_node) }
          internal_nodes << duped_node
        end
      end

      instance.instance_variable_set(:@doc, StringDoc.from_nodes(nodes))
      instance.instance_variable_set(:@transforms, @transforms)

      instance.instance_variable_set(:@internal_nodes, internal_nodes)

      instance.instance_variable_set(:@pipeline, @pipeline.dup)

      instance
    end

    def finalize_labels(keep: [])
      nodes.each do |node|
        node.finalize_labels(keep: keep)
      end
    end

    def freeze(*)
      pipeline
      super
    end

    # @api private
    attr_writer :parent

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

      @internal_nodes = StringDoc.nodes_from_doc_or_string(replacement)
    end

    def remove(label = true, descend = true)
      internal_nodes.each do |node|
        node.remove(label, descend)
      end

      @internal_nodes = []
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
      if (node = internal_nodes.first)
        node.label(name)
      end
    end

    def labeled?(name)
      if (node = internal_nodes.first)
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
      return enum_for(:each, descend: descend) unless block

      yield self

      nodes.each do |node|
        # Yield each node that isn't an internal node (e.g. added before/after).
        #
        unless @internal_nodes.any? { |internal_node| internal_node.equal?(node) }
          case node
          when MetaNode
            node.each do |each_meta_node|
              yield each_meta_node
            end
          else
            yield node
          end
        end
      end
    end

    def each_significant_node(type, descend: false, &block)
      return enum_for(:each_significant_node, type, descend: descend) unless block

      internal_nodes.each do |node|
        node.each_significant_node(type, descend: descend, &block)
      end
    end

    def each_significant_node_without_descending_into_type(type, descend: false, &block)
      return enum_for(:each_significant_node_without_descending_into_type, type, descend: descend) unless block

      internal_nodes.each do |node|
        node.each_significant_node_without_descending_into_type(type, descend: descend, &block)
      end
    end

    def each_significant_node_with_name(type, name, descend: false, &block)
      return enum_for(:each_significant_node_with_name, type, name, descend: descend) unless block

      internal_nodes.each do |node|
        node.each_significant_node_with_name(type, name, descend: descend, &block)
      end
    end

    def find_first_significant_node(type, descend: false)
      internal_nodes.each do |node|
        if (found = node.find_first_significant_node(type, descend: descend))
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

    def removed?
      internal_nodes.all?(&:removed?)
    end

    # Converts the node to an xml string.
    #
    def render(output = +"", context: nil)
      if transforms_itself?
        __transform(output, context: context)
      else
        nodes.each do |each_node|
          each_node.render(output, context: context)
        end
      end

      output
    end
    alias_method :to_html, :render
    alias_method :to_xml, :render

    # Returns the node as an xml string, without transforming.
    #
    def to_s
      nodes.each_with_object(+"") do |node, string|
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
      while (transform = node.next_transform)
        return_value = transform.call(node, context, string)

        case return_value
        when NilClass
          return
        when StringDoc
          return_value.render(string, context: context)
          return
        when Node, MetaNode
          if return_value.removed?
            return
          else
            current = return_value
          end
        else
          string << return_value.to_s
          return
        end
      end

      current.render(string, context: context)
    end
  end
end
