module Pakyow
  module Presenter
    class StringDoc
      attr_reader :structure

      TITLE_REGEX = /<title>(.*?)<\/title>/

      def initialize(html)
        @structure = StringDocParser.new(html).structure
      end

      def self.from_structure(structure, node: nil)
        instance = allocate
        instance.instance_variable_set(:@structure, structure)
        instance.instance_variable_set(:@node, node)
        return instance
      end

      def self.ensure(object)
        return object if object.is_a?(StringDoc)
        StringDoc.new(object)
      end

      def initialize_copy(original_doc)
        super

        original_structure = original_doc.instance_variable_get(:@structure)
        @structure = Utils::Dup.deep(original_structure) if original_structure

        original_node = original_doc.instance_variable_get(:@node)
        if original_node
          node_index = original_structure.index(original_node)
          @node = @structure[node_index]
        end
      end

      # Creates a StringDoc instance with the same structure, but a duped node.
      #
      def soft_copy
        StringDoc.from_structure(@structure, node: @node ? Utils::Dup.deep(@node) : nil)
      end

      def title
        title_search do |n, match|
          return match[1]
        end
      end

      def title=(title)
        title_search do |n, match|
          n.gsub!(TITLE_REGEX, "<title>#{title}</title>")
        end
      end

      def set_attribute(name, value)
        return if attributes.nil?
        attributes[name.to_sym] = value
      end
      alias :update_attribute :set_attribute

      def get_attribute(name)
        attributes[name.to_sym]
      end

      def remove_attribute(name)
        attributes.delete(name.to_sym)
      end

      def remove
        @structure.delete_if { |n| n.equal?(node) }
      end

      def clear
        children.clear
      end

      def text
        html.gsub(/<[^>]*>/, '')
      end

      def text=(text)
        clear
        children << [text, {}, []]
      end

      def html
        StringDocRenderer.render(children)
      end

      def html=(html)
        clear
        children << [html, {}, []]
      end

      def append(doc)
        doc = StringDoc.ensure(doc)

        if doc.node?
          children.push(doc.node)
        else
          children.concat(doc.structure)
        end
      end

      def prepend(doc)
        doc = StringDoc.ensure(doc)

        if doc.node?
          children.unshift(doc.node)
        else
          children.unshift(*doc.structure)
        end
      end

      def after(doc)
        doc = StringDoc.ensure(doc)

        if doc.node?
          @structure.push(doc.node)
        else
          @structure.concat(doc.structure)
        end
      end

      def before(doc)
        doc = StringDoc.ensure(doc)

        if doc.node?
          @structure.unshift(doc.node)
        else
          @structure.unshift(*doc.structure)
        end
      end

      def replace(doc)
        doc = StringDoc.ensure(doc)
        index = @structure.index(node) || 0

        if doc.node?
          @structure.insert(index + 1, node)
        else
          @structure.insert(index + 1, *doc.structure)
        end

        @structure.delete_at(index)
      end

      def scope(scope_name)
        scopes.select { |b| b[:scope] == scope_name }
      end

      def prop(scope_name, prop_name)
        return [] unless scope = scopes.select { |s| s[:scope] == scope_name }[0]
        scope[:props].select { |p| p[:prop] == prop_name }
      end

      def container(name)
        containers.fetch(name, {})[:doc]
      end

      def containers
        find_containers(@node ? [@node] : @structure)
      end

      def partials
        find_partials(@node ? [@node] : @structure)
      end

      def scopes
        find_scopes(@node ? [@node] : @structure)
      end

      def to_html
        StringDocRenderer.render(@node ? [@node] : @structure)
      end
      alias :to_s :to_html

      def ==(o)
        #TODO do this without rendering?
        # (at least in the case of comparing StringDoc to StringDoc)
        to_s == o.to_s
      end

      def node
        return @structure if @structure.empty?
        return @node || @structure[0]
      end

      def node?
        !@node.nil?
      end

      def tagname
        node[0].gsub(/[^a-zA-Z]/, '')
      end

      def option(value: nil)
        StringDoc.from_structure(node[2][0][2].select { |option|
          option[1][:value] == value
        })
      end

      private

      def title_search
        @structure.flatten.each do |n|
          next unless n.is_a?(String)
          if match = n.match(TITLE_REGEX)
            yield n, match
          end
        end
      end

      # Returns the structure representing the attributes for the node
      #
      def attributes
        node[1]
      end

      def children
        node[2][0][2]
      end

      def find_containers(structure, primary_structure = @structure, containers = {})
        return {} if structure.empty?
        structure.inject(containers) { |s, e|
          if e[1].has_key?(:container)
            s[e[1][:container]] = { doc: StringDoc.from_structure(primary_structure, node: e) }
          end
          find_containers(e[2], e[2], s)
          s
        } || {}
      end

      def find_partials(structure, primary_structure = @structure, partials = {})
        structure.inject(partials) { |s, e|
          if e[1].has_key?(:partial)
            s[e[1][:partial]] = StringDoc.from_structure(primary_structure, node: e)
          end
          find_partials(e[2], e[2], s)
          s
        } || {}
      end

      def find_scopes(structure, primary_structure = @structure, scopes = [])
        ret_scopes = structure.inject(scopes) { |s, e|
          if e[1].has_key?(:'data-scope')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              scope: e[1][:'data-scope'].to_sym,
              props: find_props(e[2]),
              nested: find_scopes(e[2]),
            }
          end
          # only find scopes if `e` is the root node or we're not decending into a nested scope
          find_scopes(e[2], e[2], s) if e == node || !e[1].has_key?(:'data-scope')
          s
        } || []

        ret_scopes
      end

      def find_props(structure, primary_structure = @structure, props = [])
        structure.inject(props) { |s, e|
          if e[1].has_key?(:'data-prop')
            s << {
              doc: StringDoc.from_structure(primary_structure, node: e),
              prop: e[1][:'data-prop'].to_sym,
            }
          end
          unless e[1].has_key?(:'data-scope')
            find_props(e[2], e[2], s)
          end
          s
        } || []
      end
    end
  end
end
