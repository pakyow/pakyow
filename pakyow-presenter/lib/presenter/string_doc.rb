module Pakyow
  module Presenter
    class StringDocParser
      PARTIAL_REGEX = /<!--\s*@include\s*([a-zA-Z0-9\-_]*)\s*-->/
      CONTAINER_REGEX = /@container( ([a-zA-Z0-9\-_]*))*/

      def initialize(html)
        @html = html
        structure
      end

      def structure
        @structure ||= parse(@html)
      end

      def containers
        find_containers(@structure)
      end

      def partials
        find_partials(@structure)
      end

      def scopes
        find_scopes(@structure)
      end

      private

      # Parses HTML and returns a nested structure representing the document.
      #
      def parse(string, writer = '')
        structure = []

        doc = doc_from_string(string)
        if doc.is_a?(Nokogiri::HTML::Document)
          structure << '<!DOCTYPE html>'
        end

        breadth_first(doc) do |node|
          next if node == doc

          children = node.children.reject {|n| n.is_a?(Nokogiri::XML::Text)}
          attributes = node.attributes
          if children.empty? && !significant?(node)
            structure << node.to_html
            throw :reject
          else
            if significant?(node)
              if scope?(node) || prop?(node)
                attr_structure = attributes.inject({}) do |attrs, attr|
                  attrs[attr[1].name.to_sym] = attr[1].value
                  attrs
                end

                closing = [['>', {}, parse(node.inner_html)]]
                closing << ["</#{node.name}>", {}, []] unless self_closing?(node.name)
                structure << ["<#{node.name} ", attr_structure, closing]
              elsif container?(node)
                match = node.text.strip.match(CONTAINER_REGEX)
                name = (match[2] || :default).to_sym
                structure << [node.to_html, { container: name }, []]
              elsif partial?(node)
                next unless match = node.to_html.strip.match(PARTIAL_REGEX)
                name = match[1].to_sym
                structure << [node.to_html, { partial: name }, []]
              end

              throw :reject
            else
              attr_s = attributes.inject('') { |s, a|
                s << " #{a[1].name}=\"#{a[1].value}\""
                s
              }

              attr_structure = attributes.inject({}) do |attrs, attr|
                attrs[attr[1].name.to_sym] = attr[1].value
                attrs
              end

              closing = [['>', {}, parse(node.inner_html)]]
              closing << ["</#{node.name}>", {}, []] unless self_closing?(node.name)
              structure << ["<#{node.name} ", attr_structure, closing]
              throw :reject
            end
          end
        end

        return structure
      end

      def significant?(node)
        scope?(node) || prop?(node) || container?(node) || partial?(node)
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

      def breadth_first(doc)
        queue = [doc]
        until queue.empty?
          catch(:reject) do
            node = queue.shift
            yield node
            queue.concat(node.children)
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

      def find_containers(structure, containers = {})
        structure.inject(containers) { |s, e|
          if e[1].has_key?(:container)
            s[e[1][:container]] = e[0]
          end
          find_containers(e[2], s)
          s
        } || {}
      end

      def find_partials(structure, partials = {})
        structure.inject(partials) { |s, e|
          if e[1].has_key?(:partial)
            s[e[1][:partial]] = e[0]
          end
          find_partials(e[2], s)
          s
        } || {}
      end

      def find_scopes(structure, scopes = [])
        ret_scopes = structure.inject(scopes) { |s, e|
          if e[1].has_key?(:'data-scope')
            s << {
              doc: structure,
              scope: e[1][:'data-scope'].to_sym,
              props: find_props(e[2]),
              nested: find_scopes(e[2]),
            }
          end
          find_scopes(e[2], s)
          s
        } || []

        #TODO is this something we still want to support?
        # # find unscoped props
        # if !structure.empty? && !structure[0][1].has_key?(:'data-scope')
        #   ret_scopes.unshift({
        #     scope: nil,
        #     props: find_props(structure),
        #     nested: [],
        #   })
        # end

        ret_scopes
      end

      def find_props(structure, props = [])
        structure.inject(props) { |s, e|
          if e[1].has_key?(:'data-prop')
            s << {
              doc: structure,
              prop: e[1][:'data-prop'].to_sym,
            }
          end
          unless e[1].has_key?(:'data-scope')
            find_props(e[2], s)
          end
          s
        } || []
      end
    end

    class StringDocRenderer
      def self.render(structure)
        flatten(structure).flatten.join
      end

      def self.flatten(structure)
        structure.map { |content|
          content.is_a?(Array) ? contentify(content) : content
        }
      end

      def self.contentify(content)
        content.map { |p|
          if p.is_a?(Hash)
            attrify(p)
          elsif p.is_a?(Array)
            flatten(p)
          else
            p
          end
        }
      end

      def self.attrify(attrs)
        attrs.map { |attr|
          #TODO do this without interpolation?
          "#{attr[0]}=\"#{attr[1]}\""
        }.join(' ')
      end
    end

    class StringDoc
      def initialize(html)
        parser = StringDocParser.new
        @structure = parser.structure
        @containers = parser.containers
        @partials = parser.partials
        @scopes = parser.scopes
      end

      def initialize_copy(doc)
        # NOTE we shouldn't need the parser around, just the structures
        #
        instance = allocate
        #TODO set other things
        return instance
      end

      # Returns a hash, where key is the container name and value is the doc
      # that represents the container.
      #
      def containers
        #TODO
      end

      def to_html
        StringDocRenderer.render(@structure)
      end

    end
  end
end

