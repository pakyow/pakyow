module Pakyow
  module Presenter
    # @api private
    class StringNode
      attr_reader :node, :type, :name, :parent

      def initialize(node, type: nil, name: nil, parent: nil)
        @node, @type, @name, @parent = node, type, name, parent
      end

      def initialize_copy(original)
        super

        @node = node.dup
        @node[1] = attributes.dup
        @node[3] = children.dup
      end

      def close(tag, child)
        node << (tag ? ">" : "")
        node << StringDoc.from_nodes(child)
        node << ((tag && !DocHelpers.self_closing_tag?(tag)) ? "</#{tag}>" : "")
      end

      def attributes
        node[1]
      end

      def children
        node[3]
      end

      # TODO: delegator
      def props
        children.props
      end

      # TODO: delegator
      def scopes
        children.scopes
      end

      def with_children
        return [self] unless children
        [self].concat(children.nodes.map(&:with_children))
      end

      def empty?
        node.empty?
      end

      def replace(replacement)
        if replacement.is_a?(StringDoc)
          @node = ["", "", "", replacement, ""]
        else
          # TODO: ?
        end
      end

      def remove
        # TODO: consider also removing from `parent`
        @node = []
      end

      def to_s
        node.flatten.map(&:to_s).join
      end

      # TODO: revisit
      # def text
      #   html.gsub(/<[^>]*>/, '')
      # end

      # TODO: revisit
      # if we want to support this, it should only replace the text of this node... not everything
      # def text=(text)
      #   clear
      #   children << [text, {}, []]
      # end

      def html
        node.render
      end

      def html=(html)
        children.replace(html)
      end

      def tagname
        node[0].gsub(/[^a-zA-Z]/, '')
      end

      # TODO: revisit
      # def option(value: nil)
      #   StringDoc.from_structure(node[2][0][2].select { |option|
      #     option[1][:value] == value.to_s
      #   })
      # end

      def after(node)
        parent.insert_after(node, self)
      end
    end
  end
end
