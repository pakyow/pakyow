module Pakyow
  module Presenter
    class StringDocParser
      PARTIAL_REGEX = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/
      CONTAINER_REGEX = /@container( ([a-zA-Z0-9\-_]*))*/
      SIGNIFICANT = [:scope?, :prop?, :container?, :partial?, :option?, :component?]

      def initialize(html)
        @html = html
        structure
      end

      def structure
        @structure ||= parse(doc_from_string(@html))
      end

      private

      # Parses HTML and returns a nested structure representing the document.
      #
      def parse(doc)
        structure = []

        if doc.is_a?(Nokogiri::HTML::Document)
          structure << ['<!DOCTYPE html>', {}, []]
        end

        breadth_first(doc) do |node, queue|
          if node == doc
            queue.concat(node.children)
            next
          end

          children = node.children.reject {|n| n.is_a?(Nokogiri::XML::Text)}
          attributes = node.attributes
          if !structure.empty? && children.empty? && !significant?(node)
            structure << [node.to_html, {}, []]
          else
            if significant?(node)
              if container?(node)
                match = node.text.strip.match(CONTAINER_REGEX)
                name = (match[2] || :default).to_sym
                structure << [node.to_html, { container: name }, []]
              elsif partial?(node)
                next unless match = node.to_html.strip.match(PARTIAL_REGEX)
                name = match[1].to_sym
                structure << [node.to_html, { partial: name }, []]
              else
                attr_structure = attributes.inject({}) do |attrs, attr|
                  attrs[attr[1].name.to_sym] = attr[1].value
                  attrs
                end

                closing = [['>', {}, parse(node)]]
                closing << ["</#{node.name}>", {}, []] unless self_closing?(node.name)
                structure << ["<#{node.name} ", attr_structure, closing]
              end
            else
              if node.is_a?(Nokogiri::XML::Text)
                structure << [node.text, {}, []]
              else
                attr_s = attributes.inject('') { |s, a| s << " #{a[1].name}=\"#{a[1].value}\""; s }
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
        return false unless node['data-scope']
        return true
      end

      def prop?(node)
        return false unless node['data-prop']
        return true
      end

      def container?(node)
        return false unless node.is_a?(Nokogiri::XML::Comment)
        return false unless node.text.strip.match(CONTAINER_REGEX)
        return true
      end

      def partial?(node)
        return false unless node.is_a?(Nokogiri::XML::Comment)
        return false unless node.to_html.strip.match(PARTIAL_REGEX)
        return true
      end

      def option?(node)
        node.name == 'option'
      end

      def component?(node)
        return false unless node['data-ui']
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
        if string.match(/<html.*>/)
          Nokogiri::HTML::Document.parse(string)
        else
          Nokogiri::HTML.fragment(string)
        end
      end

      SELF_CLOSING = %w[area base basefont br hr input img link meta]
      def self_closing?(tag)
        SELF_CLOSING.include? tag
      end

    end
  end
end
