require "pakyow/support/silenceable"

module Pakyow
  module Presenter
    class StringDocParser
      include Support::Silenceable

      PARTIAL_REGEX = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/
      CONTAINER_REGEX = /@container( ([a-zA-Z0-9\-_]*))*/
      SIGNIFICANT = [:scope?, :prop?, :container?, :partial?, :option?, :component?]

      attr_reader :structure

      def initialize(html)
        silence_warnings do
          @structure = parse(doc_from_string(html))
        end
      end

      private

      # Parses HTML and returns a nested structure representing the document.
      #
      def parse(doc)
        structure = []

        unless doc.is_a?(Oga::XML::Element) || !doc.respond_to?(:doctype) || doc.doctype.nil?
          structure << ['<!DOCTYPE html>', {}, []]
        end

        breadth_first(doc) do |node, queue|
          if node == doc
            queue.concat(node.children.to_a)
            next
          end

          children = node.children.reject {|n| n.is_a?(Oga::XML::Text)}

          if node.is_a?(Oga::XML::Element)
            attributes = node.attributes
          else
            attributes = []
          end

          if !structure.empty? && children.empty? && !significant?(node)
            structure << [node.to_xml, {}, []]
          else
            if significant?(node)
              if container?(node)
                match = node.text.strip.match(CONTAINER_REGEX)
                name = (match[2] || :default).to_sym
                structure << [node.to_xml, { container: name }, []]
              elsif partial?(node)
                next unless match = node.to_xml.strip.match(PARTIAL_REGEX)
                name = match[1].to_sym
                structure << [node.to_xml, { partial: name }, []]
              else
                attr_structure = attributes.inject({}) do |attrs, attr|
                  attrs[attr.name.to_sym] = attr.value
                  attrs
                end

                closing = [['>', {}, parse(node)]]
                closing << ["</#{node.name}>", {}, []] unless self_closing?(node.name)
                structure << ["<#{node.name} ", attr_structure, closing]
              end
            else
              if node.is_a?(Oga::XML::Text) || node.is_a?(Oga::XML::Comment)
                structure << [node.to_xml, {}, []]
              else
                attr_s = attributes.inject('') { |s, a| s << " #{a.name}=\"#{a.value}\""; s }
                closing = [['>', {}, parse(node)]]
                closing << ['</' + node.name + '>', {}, []] unless self_closing?(node.name)
                structure << ['<' + node.name + attr_s, {}, closing]
              end
            end
          end
        end

        return structure
      end

      def significant?(node)
        SIGNIFICANT.each do |method|
          return true if send(method, node)
        end

        false
      end

      def scope?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-scope')
        return true
      end

      def prop?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-prop')
        return true
      end

      def container?(node)
        return false unless node.is_a?(Oga::XML::Comment)
        return false unless node.text.strip.match(CONTAINER_REGEX)
        return true
      end

      def partial?(node)
        return false unless node.is_a?(Oga::XML::Comment)
        return false unless node.to_xml.strip.match(PARTIAL_REGEX)
        return true
      end

      def option?(node)
        return false unless node.is_a?(Oga::XML::Element)
        node.name == 'option'
      end

      def component?(node)
        return false unless node.is_a?(Oga::XML::Element)
        return false unless node.attribute('data-ui')
        return true
      end

      def breadth_first(doc)
        queue = [doc]
        until queue.empty?
          catch(:reject) do
            node = queue.shift
            yield node, queue
          end
        end
      end

      def doc_from_string(string)
        Oga.parse_html(string)
      end

      SELF_CLOSING = %w[area base basefont br hr input img link meta]
      def self_closing?(tag)
        SELF_CLOSING.include? tag
      end

    end
  end
end
