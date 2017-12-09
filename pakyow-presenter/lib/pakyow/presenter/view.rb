# frozen_string_literal: true

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

      def_delegators :@object, :type, :name, :text, :html, :label, :labeled?

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

        if @object.respond_to?(:attributes)
          self.attributes = @object.attributes
        else
          @attributes = nil
        end
      end

      def initialize_copy(_)
        super

        @object = object.dup

        if @object.respond_to?(:attributes)
          self.attributes = @object.attributes
        else
          @attributes = nil
        end
      end

      def find(*names)
        named = names.shift.to_sym
        found = props_and_scopes_with_name(named).each_with_object([]) { |node, arr|
          arr << View.new(object: node)
        }

        if names.empty? # found everything; wrap it up
          # TODO: handle case where `found` is empty
          VersionedView.new(found)
        elsif found.count > 0 # descend further
          # TODO: confirm we actually want to return the first one instead
          # of the default / working version (e.g. how to find and use some
          # version then present data to a nested scope)
          found.first.find(*names)
        else
          nil
        end
      end

      def find_all(*names)
        # TODO
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
        @info[key]
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

      def form(_name)
        if form_node = @object.find_significant_nodes(:form)[0]
          Form.new(object: form_node)
        else
          nil
        end
      end

      def title
        if title_node = @object.find_significant_nodes(:title)[0]
          View.new(object: title_node)
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
        # TODO: should bind recursively through `object`

        return if object.nil?

        props.each do |prop|
          bind_value_to_node(object[prop.name], prop)
        end

        attributes[:"data-id"] = object[:id]

        self
      end

      # call-seq:
      #   apply(data)
      #
      # Transform self to object then binds object to the view.
      #
      def present(object)
        transform(object) do |view, presentable|
          yield view, presentable if block_given?
        end

        bind(object)
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
        @attributes
      end

      alias attrs attributes

      def attributes=(attributes)
        @attributes = ViewAttributes.new(attributes)
      end

      alias attrs= attributes=

      def version
        (label(:version) || VersionedView::DEFAULT_VERSION).to_sym
      end

      def to_html(clean: true)
        cleanup_versions if clean
        @object.to_html
      end

      alias :to_s :to_html

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

      def props_with_name(name)
        @object.find_significant_nodes_with_name(:prop, name)
      end

      def scopes_with_name(name)
        @object.find_significant_nodes_with_name(:scope, name)
      end

      def props_and_scopes_with_name(name)
        props_with_name(name) + scopes_with_name(name)
      end

      def cleanup_versions
        versioned_nodes.each do |node_set|
          node_set.each do |node|
            node.remove unless node.label(:version) == VersionedView::DEFAULT_VERSION
          end
        end
      end

      def versioned_nodes(nodes = object_nodes, versions = [])
        versions << nodes.select { |node|
          node.type && node.attributes.is_a?(StringAttributes) && node.label(:version)
        }

        nodes.each do |node|
          if children = node.children
            versioned_nodes(children.nodes, versions)
          end
        end

        versions.reject(&:empty?)
      end

      def object_nodes
        if @object.is_a?(StringDoc)
          @object.nodes
        else
          [@object]
        end
      end
    end
  end
end
