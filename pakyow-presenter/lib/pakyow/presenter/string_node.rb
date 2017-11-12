require "forwardable"

module Pakyow
  module Presenter
    # @api private
    class StringNode
      class << self
        SELF_CLOSING = %w[area base basefont br hr input img link meta].freeze
        FORM_INPUTS = %w[input select textarea button].freeze
        WITHOUT_VALUE = %w[select].freeze

        def self_closing?(tag)
          SELF_CLOSING.include? tag
        end

        def form_input?(tag)
          FORM_INPUTS.include? tag
        end

        def without_value?(tag)
          WITHOUT_VALUE.include? tag
        end
      end

      attr_reader :node, :type, :name, :parent
      attr_writer :parent

      extend Forwardable
      def_delegators :children, :find_significant_nodes, :find_significant_nodes_with_name

      def initialize(node, type: nil, name: nil, parent: nil, labels: {})
        @node, @type, @name, @parent, @labels = node, type, name, parent, labels
      end

      def initialize_copy(original)
        super

        @node = node.dup
        @node[1] = attributes.dup
        @node[3] = children.dup

        @labels = @labels.dup
      end

      def close(tag, child)
        node << (tag ? ">" : "")
        node << StringDoc.from_nodes(child)
        node << ((tag && !self.class.self_closing?(tag)) ? "</#{tag}>" : "")
        self
      end

      def attributes
        node[1]
      end

      def children
        node[3]
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
          @node = ["", StringAttributes.new, "", replacement, ""]
        else
          # TODO: ?
        end
      end

      def remove
        # TODO: consider also removing from `parent`
        @node = []
      end

      def to_html
        node.flatten.map(&:to_s).join
      end

      alias :to_s :to_html

      def string_nodes
        [node[0], node[1], node[2], node[3]&.string_nodes, node[4]]
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
        @tagname ||= node[0].gsub(/[^a-zA-Z]/, "")
      end

      def clear
        children.clear
      end

      def after(node)
        parent.insert_after(node, self)
      end

      def append(node)
        children.append(node)
      end

      def prepend(node)
        children.prepend(node)
      end

      def label(name)
        @labels[name.to_sym]
      end

      def labeled?(name)
        @labels.key?[name.to_sym]
      end

      # TODO: it would be nice if Inspectable could handle this
      def inspect
        inspection = [:type, :name, :attributes, :children].map { |attr|
          value = send(attr)
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)
          "#{attr}: #{value.inspect}"
        }.compact.join(" ")

        "#<#{self.class.name}:#{self.object_id}#{inspection}>"
      end
    end
  end
end
