module Pakyow
  module Presenter
    # @api private
    class StringNode
      attr_reader :node, :type, :name

      def initialize(node, type: nil, name: nil)
        @node, @type, @name = node, type, name
      end

      def initialize_copy(original)
        super

        @node = node.dup
        @node[1] = attributes.dup
        @node[3] = doc.dup
      end

      def close(tag, child)
        node << (tag ? ">" : "")
        node << StringDoc.from_structure(child)
        node << ((tag && !DocHelpers.self_closing_tag?(tag)) ? "</#{tag}>" : "")
      end

      def attributes
        node[1]
      end

      def doc
        node[3]
      end

      # TODO: delegator
      def props
        doc.props
      end

      # TODO: delegator
      def scopes
        doc.scopes
      end

      def with_children
        return [self] unless doc
        [self].concat(doc.structure.map(&:with_children))
      end

      def empty?
        node.empty?
      end

      def replace(replacement)
        if replacement.is_a?(StringDoc)
          @node = ["", StringAttributes.new, "", replacement, ""]
        else
          # TODO: ?
        end
      end

      def remove
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
        doc.replace(html)
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
    end
  end
end
