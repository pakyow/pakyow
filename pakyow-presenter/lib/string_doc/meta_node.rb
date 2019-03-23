# frozen_string_literal: true

class StringDoc
  class MetaNode
    attr_reader :nodes, :parent

    # @api private
    attr_writer :parent

    def initialize(nodes)
      @nodes = nodes
      @parent = nodes.first.parent
      @transforms = { high: [], default: [], low: [] }
      @nodes.each do |node|
        node.parent = self
      end
    end

    # @api private
    def initialize_copy(_)
      super

      @nodes = @nodes.map { |node|
        duped_node = node.dup
        duped_node.parent = self
        duped_node
      }
      @transforms = Hash[@transforms.map { |k, v| [k, v.dup] }]
    end

    def replace_node(node, replacement)
      if replace_node_index = @nodes.index(node)
        @nodes[replace_node_index] = replacement
        replacement.parent = self
      end

      self
    end

    def remove_node(node)
      if remove_node_index = @nodes.index(node)
        @nodes.delete_at(remove_node_index)
      end

      self
    end

    def insert_after(insertable, node)
      if after_node_index = @nodes.index(node)
        insertable_nodes = StringDoc.nodes_from_doc_or_string(insertable)
        @nodes.insert(after_node_index + 1, *insertable_nodes)
        insertable_nodes.each do |insertable_node|
          insertable_node.parent = self
        end
      end
    end

    def insert_before(insertable, node)
      if before_node_index = @nodes.index(node)
        insertable_nodes = StringDoc.nodes_from_doc_or_string(insertable)
        @nodes.insert(before_node_index, *insertable_nodes)
        insertable_nodes.each do |insertable_node|
          insertable_node.parent = self
        end
      end
    end

    def call_next_transform
      (@transforms[:high].shift || @transforms[:default].shift || @transforms[:low].shift).call(self)
    end

    def transform(priority: :default, &block)
      @transforms[priority] << block; block.object_id
    end

    def transforms?
      transforms_itself? || @children.transforms?
    end

    def transforms_itself?
      @transforms[:high].any? || @transforms[:default].any? || @transforms[:low].any?
    end
  end
end
