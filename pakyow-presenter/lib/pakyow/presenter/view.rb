require "forwardable"

require "pakyow/presenter/helpers"

module Pakyow
  module Presenter
    class View
      class << self
        # Creates a view from a file.
        #
        def load(path, content: nil)
          new(content || File.read(path))
        end
      end

      extend Forwardable

      def_delegators :@object, :type, :name, :title=, :title, :text, :html, :to_html, :to_s

      # The object responsible for parsing, manipulating, and rendering
      # the underlying HTML document for the view.
      #
      attr_reader :object

      include Helpers

      # Creates a view with +html+.
      #
      # FIXME: only accept html here, create #from_object method
      def initialize(html = "", object: nil)
        @info = {}
        @info, html = FrontMatterParser.parse_and_scrub(html) unless html.empty?

        @object = object ? object : StringDoc.new(html)
      end

      def initialize_copy(_)
        super
        @object = object.dup
      end

      def find(*names)
        name = names.shift

        found = @object.find_significant_nodes_with_name(:prop, name, with_children: false).concat(@object.find_significant_nodes_with_name(:scope, name)).each_with_object(ViewSet.new(name: name)) { |significant, set|
          set << View.new(object: significant)
        }

        if names.empty?
          found
        else
          found.find(*names)
        end
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      def with
        yield self; self
      end

      def info(key = nil)
        return @info if key.nil?
        return @info[key]
      end

      def add_info(*infos)
        infos.each do |info|
          @info.merge!(Hash.symbolize(info))
        end

        self
      end

      def container(name)
        @object.find_significant_nodes_with_name(:container, name)[0]
      end

      def partial(name)
        @object.find_significant_nodes_with_name(:partial, name).each_with_object(ViewSet.new) { |partial, set|
          set << View.new(object: partial)
        }
      end

      def component(name)
        @object.find_significant_nodes_with_name(:component, name).each_with_object(ViewSet.new) { |component, set|
          set << View.new(object: component)
        }
      end

      def form(name)
        if form_node = @object.find_significant_nodes(:form)[0]
          Form.new(object: form_node)
        else
          nil
        end
      end

      def transform(object)
        # TODO: should transform recursively through `object`

        if object.nil?
          remove
        else
          props.each do |prop|
            next if object.key?(prop.name)
            prop.remove
          end
        end

        yield self, object if block_given?

        self
      end

      # call-seq:
      #   bind(data)
      #
      # Binds a single datum across existing scopes.
      #
      def bind(object)
        return if object.nil?

        # TODO: should bind recursively through `object`

        props.each do |prop|
          bind_value_to_node(object[prop.name], prop)
        end

        attrs[:"data-id"] = object[:id]
        yield self, object if block_given?
        self
      end

      # call-seq:
      #   apply(data)
      #
      # Transform self to object then binds object to the view.
      #
      def present(object)
        transform(object).bind(object)
      end

      def append(view)
        # TODO: handle string (with sanitization) / collection
        @object.append(view.object)
        self
      end

      def prepend(view)
        # TODO: handle string (with sanitization) / collection
        @object.prepend(view.object)
        self
      end

      def after(view)
        # TODO: handle string (with sanitization) / collection
        @object.after(view.object)
        self
      end

      def before(view)
        # TODO: handle string (with sanitization) / collection
        @object.before(view.object)
        self
      end

      def replace(view)
        # TODO: handle string (with sanitization) / collection
        @object.replace(view.object)
        self
      end

      def remove
        @object.remove
        self
      end

      def clear
        @object.clear
        self
      end

      def text=(text)
        # FIXME: IIRC we support this for bindings; seems like a weird thing to do here
        text = text.call(self.text) if text.is_a?(Proc)
        @object.text = text
      end

      def html=(html)
        # FIXME: IIRC we support this for bindings; seems like a weird thing to do here
        html = html.call(self.html) if html.is_a?(Proc)
        @object.html = html
      end

      def decorated?
        @object.type == :scope || @object.type == :prop
      end

      def container?
        @object.type == :container
      end

      def partial?
        @object.type == :partial
      end

      def component?
        @object.type == :component
      end

      def form?
        @object.type == :form
      end

      def ==(other)
        other.is_a?(self.class) && @object == other.object
      end

      def attributes
        return @attributes if @attributes
        self.attributes = @object.attributes
      end

      alias attrs attributes

      def attributes=(attributes)
        @attributes = Attributes.new(attributes)
      end

      alias attrs= attributes=

      # @api private
      def scopes
        @object.find_significant_nodes(:scope)
      end

      # @api private
      def props
        @object.find_significant_nodes(:prop, with_children: false)
      end

      # @api private
      def mixin(partials)
        object.find_significant_nodes(:partial).each do |partial_node|
          next unless partial = partials[partial_node.name]

          replacement = partial
          replacement.mixin(partials)

          partial_node.replace(replacement.object)
        end

        self
      end

      protected

      def bind_value_to_node(value, view)
        tag = view.tagname
        return if StringNode.without_value?(tag)

        value = String(value)

        if StringNode.self_closing?(tag)
          view.attributes[:value] = ensure_html_safety(value) if view.attributes[:value].nil?
        else
          view.html = ensure_html_safety(value)
        end
      end
    end
  end
end
