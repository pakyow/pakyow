require "pakyow/support/silenceable"

module Pakyow
  module Presenter
    class StringDocParser
      include Support::Silenceable

      PARTIAL_REGEX = /@include\s*([a-zA-Z0-9\-_]*)/.freeze
      CONTAINER_REGEX = /@container\s*([a-zA-Z0-9\-_]*)/.freeze

      def self.significant(name, &block)
        significant_types[name] = block
      end

      def self.significant_types
        @significant_types ||= {}
      end

      significant :scope do |node|
        node.is_a?(Oga::XML::Element) && node.attribute('data-scope')
      end

      significant :prop do |node|
        node.is_a?(Oga::XML::Element) && node.attribute('data-prop')
      end

      significant :container do |node|
        node.is_a?(Oga::XML::Comment) && node.text.strip.match(CONTAINER_REGEX)
      end

      significant :partial do |node|
        node.is_a?(Oga::XML::Comment) && node.to_xml.strip.match(PARTIAL_REGEX)
      end

      significant :option do |node|
        node.is_a?(Oga::XML::Element) && node.name == 'option'
      end

      significant :component do |node|
        node.is_a?(Oga::XML::Element) && node.attribute('data-ui')
      end

      attr_reader :structure

      def initialize(html)
        silence_warnings do
          @structure = parse(doc_from_string(html))
        end
      end

      protected

      # Parses HTML and returns a nested structure representing the document.
      #
      def parse(doc)
        structure = []

        unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
          structure << ["<!DOCTYPE html>", {}, []]
        end

        breadth_first(doc) do |node, queue|
          if node == doc
            queue.concat(node.children.to_a); next
          end

          # TODO: why do we do this? optimization?
          children = node.children.reject {|n| n.is_a?(Oga::XML::Text)}

          # this is an optimization we can make because we don't care about this node and
          # we know that nothing inside of it is significant, so we can just collapse it
          if !structure.empty? && children.empty? && !significant?(node)
            structure << [node.to_xml, {}, []]; next
          end

          if significant?(node)
            case significance(node)
            when :container
              structure << [node.to_xml, { container: container_name(node) }, []]
            when :partial
              structure << [node.to_xml, { partial: partial_name(node) }, []]
            else
              structure << ["<#{node.name} ", attributes_hash(node), close(node)]
            end
          else # insignificant
            if node.is_a?(Oga::XML::Text) || node.is_a?(Oga::XML::Comment)
              structure << [node.to_xml, {}, []]
            else
              structure << ["<#{node.name}#{attributes_string(node)}", {}, close(node)]
            end
          end
        end

        structure
      end

      def doc_from_string(string)
        Oga.parse_html(string)
      end

      def breadth_first(doc)
        queue = [doc]
        until queue.empty?
          catch :reject do
            node = queue.shift
            yield node, queue
          end
        end
      end

      def significant?(node)
        self.class.significant_types.each do |name, block|
          return true if block.call(node)
        end

        false
      end

      def significance(node)
        self.class.significant_types.each do |name, block|
          return name if block.call(node)
        end

        nil
      end

      def container_name(node)
        (node.text.strip.match(CONTAINER_REGEX)[2] || :default).to_sym
      end

      def partial_name(node)
        node.text.strip.match(PARTIAL_REGEX)[1].to_sym
      end

      def attributes(node)
        if node.is_a?(Oga::XML::Element)
          node.attributes
        else
          []
        end
      end

      def attributes_hash(node)
        attributes(node).each_with_object({}) do |attribute, structure|
          structure[attribute.name.to_sym] = attribute.value
        end
      end

      def attributes_string(node)
        attributes(node).each_with_object("") do |attribute, string|
          string << " #{attribute.name}=\"#{attribute.value}\""
        end
      end

      def close(node)
        closing = [[">", {}, parse(node)]]
        closing << ["</#{node.name}>", {}, []] unless DocHelpers.self_closing_tag?(node.name)
        closing
      end
    end
  end
end
