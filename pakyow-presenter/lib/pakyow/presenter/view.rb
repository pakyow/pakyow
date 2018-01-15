# frozen_string_literal: true

require "forwardable"

require "pakyow/support/indifferentize"
require "pakyow/support/safe_string"

require "pakyow/presenter/helpers"

module Pakyow
  module Presenter
    # Provides an interface for manipulating view templates.
    #
    class View
      class << self
        # Creates a view from a file.
        #
        def load(path, content: nil)
          new(content || File.read(path))
        end

        # Creates a view wrapping an object.
        #
        def from_object(object)
          allocate.tap do |instance|
            instance.instance_variable_set(:@object, object)
            instance.instance_variable_set(:@info, {})
            instance.instance_variable_set(:@logical_path, nil)
            if object.respond_to?(:attributes)
              instance.attributes = object.attributes
            else
              instance.instance_variable_set(:@attributes, nil)
            end
          end
        end
      end

      include Support::SafeStringHelpers

      using Support::Indifferentize

      extend Forwardable

      def_delegators :@object, :type, :name, :text, :html, :label, :labeled?

      # The object responsible for parsing, manipulating, and rendering
      # the underlying HTML document for the view.
      #
      attr_reader :object

      # The logical path to the view template.
      #
      attr_reader :logical_path

      include Helpers

      # Creates a view with +html+.
      #
      def initialize(html, logical_path: nil)
        @info, html = FrontMatterParser.parse_and_scrub(html)
        @object = StringDoc.new(html)
        @logical_path = logical_path

        if @object.respond_to?(:attributes)
          self.attributes = @object.attributes
        else
          @attributes = nil
        end
      end

      def initialize_copy(_)
        super

        @info = @info.dup
        @object = @object.dup

        if @object.respond_to?(:attributes)
          self.attributes = @object.attributes
        else
          @attributes = nil
        end
      end

      # Finds a view binding by name. When passed more than one value, the view will
      # be traversed through each name. Returns a {VersionedView}.
      #
      def find(*names)
        named = names.shift.to_sym
        found = props_and_scopes_with_name(named).each_with_object([]) { |node, arr|
          arr << View.from_object(node)
        }

        if names.empty? && !found.empty? # found everything; wrap it up
          VersionedView.new(found)
        elsif found.count > 0 # descend further
          found.first.find(*names)
        else
          nil
        end
      end

      # Finds all view bindings by name, returning an array of {View} objects.
      #
      def find_all(named)
        props_and_scopes_with_name(named, with_children: false).each_with_object([]) { |node, arr|
          arr << View.from_object(node)
        }
      end

      # Finds a form with a binding matching +name+.
      #
      def form(name)
        if form_node = @object.find_significant_nodes_with_name(:form, name)[0]
          Form.from_object(form_node)
        else
          nil
        end
      end

      # Returns all view info when +key+ is +nil+, otherwise returns the value for +key+.
      #
      def info(key = nil)
        # FIXME: somehow we're creating views without initializing info
        return {} unless instance_variable_defined?(:@info)

        if key.nil?
          @info
        else
          @info.fetch(key, nil)
        end
      end

      # Returns a view for the +<head>+ node.
      #
      def head
        if head_node = @object.find_significant_nodes(:head)[0]
          View.from_object(head_node)
        else
          nil
        end
      end

      # Returns a view for the +<body>+ node.
      #
      def body
        if body_node = @object.find_significant_nodes(:body)[0]
          View.from_object(body_node)
        else
          nil
        end
      end

      # Returns an array of views, one for each component matching +name+.
      #
      # Components are given the +ui+ attribute in the view template. For example:
      #
      #   <div ui="some_component">...</div>
      #
      def components(name)
        @object.find_significant_nodes_with_name(:component, name).each_with_object([]) { |component, set|
          set << View.from_object(component)
        }
      end

      # Returns a view for the +<title>+ node.
      #
      def title
        if title_node = @object.find_significant_nodes(:title)[0]
          View.from_object(title_node)
        else
          nil
        end
      end

      # Yields +self+.
      #
      def with
        tap do
          yield self
        end
      end

      # Transforms +self+ to match structure of +object+.
      #
      def transform(object)
        tap do
          if object.nil? || object.empty?
            remove
          else
            props.each do |prop|
              next if object[prop.name]
              prop.remove
            end
          end

          yield self, object if block_given?
        end
      end

      # Binds a single object.
      #
      def bind(object)
        tap do
          unless object.nil?
            props.each do |prop|
              bind_value_to_node(object[prop.name], prop)
            end

            attributes[:"data-id"] = object[:id]
          end
        end
      end

      # Transform +self+ to +object+, then binds +object+.
      #
      def present(object)
        transform(object) do |view, presentable|
          yield view, presentable if block_given?
        end

        bind(object)
      end

      # Appends a view or string to +self+.
      #
      def append(view_or_string)
        tap do
          @object.append(view_from_view_or_string(view_or_string).object)
        end
      end

      # Prepends a view or string to +self+.
      #
      def prepend(view_or_string)
        tap do
          @object.prepend(view_from_view_or_string(view_or_string).object)
        end
      end

      # Inserts a view or string after +self+.
      #
      def after(view_or_string)
        tap do
          @object.after(view_from_view_or_string(view_or_string).object)
        end
      end

      # Inserts a view or string before +self+.
      #
      def before(view_or_string)
        tap do
          @object.before(view_from_view_or_string(view_or_string).object)
        end
      end

      # Replaces +self+ with a view or string.
      #
      def replace(view_or_string)
        tap do
          @object.replace(view_from_view_or_string(view_or_string).object)
        end
      end

      # Removes +self+.
      #
      def remove
        tap do
          @object.remove
        end
      end

      # Removes +self+'s children.
      #
      def clear
        tap do
          @object.clear
        end
      end

      # Safely sets the html value of +self+.
      #
      def html=(html)
        @object.html = ensure_html_safety(html)
      end

      # Returns true if +self+ is a binding.
      #
      def binding?
        @object.type == :scope || @object.type == :prop
      end

      # Returns true if +self+ is a container.
      #
      def container?
        @object.type == :container
      end

      # Returns true if +self+ is a partial.
      #
      def partial?
        @object.type == :partial
      end

      # Returns true if +self+ is a component.
      #
      def component?
        @object.labeled?(:ui)
      end

      # Returns true if +self+ is a form.
      #
      def form?
        @object.type == :form
      end

      # Returns true if +self+ equals +other+.
      #
      def ==(other)
        other.is_a?(self.class) && @object == other.object
      end

      # Returns attributes object for +self+.
      #
      def attributes
        @attributes
      end
      alias attrs attributes

      # Wraps +attributes+ in a {ViewAttributes} instance.
      #
      def attributes=(attributes)
        @attributes = ViewAttributes.new(attributes)
      end
      alias attrs= attributes=

      # Returns the version name for +self+.
      #
      def version
        (label(:version) || VersionedView::DEFAULT_VERSION).to_sym
      end

      # Converts +self+ to html, rendering the view.
      #
      # If +clean+ is +true+, unused versions will be cleaned up prior to rendering.
      #
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
        tap do
          @object.find_significant_nodes(:partial).each do |partial_node|
            if replacement = partials[partial_node.name]
              partial_node.replace(replacement.mixin(partials).object)
            end
          end
        end
      end

      # @api private
      def add_info(*infos)
        tap do
          infos.each do |info|
            @info.merge!(info.indifferentize)
          end
        end
      end

      protected

      def bind_value_to_node(value, node)
        tag = node.tagname
        return if StringNode.without_value?(tag)

        value = String(value)

        if StringNode.self_closing?(tag)
          node.attributes[:value] = ensure_html_safety(value) if node.attributes[:value].nil?
        else
          node.html = ensure_html_safety(value)
        end
      end

      def props_with_name(name, with_children: true)
        @object.find_significant_nodes_with_name(:prop, name, with_children: with_children)
      end

      def scopes_with_name(name, with_children: true)
        @object.find_significant_nodes_with_name(:scope, name, with_children: with_children)
      end

      def props_and_scopes_with_name(name, with_children: true)
        props_with_name(name, with_children: with_children) + scopes_with_name(name, with_children: with_children)
      end

      def cleanup_versions
        versioned_nodes.each do |node_set|
          node_set.each do |node|
            unless node.label(:version) == VersionedView::DEFAULT_VERSION
              node.remove
            end
          end
        end
      end

      def versioned_nodes(nodes = object_nodes, versions = [])
        versions << nodes.select { |node|
          node.type && node.attributes.is_a?(StringAttributes) && node.labeled?(:version)
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

      def view_from_view_or_string(view_or_string)
        if view_or_string.is_a?(View)
          view_or_string
        elsif view_or_string.is_a?(String)
          View.new(ensure_html_safety(view_or_string))
        else
          View.new(ensure_html_safety(view_or_string.to_s))
        end
      end
    end
  end
end
