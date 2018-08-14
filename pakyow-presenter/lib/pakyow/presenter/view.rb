# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"
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
      using Support::Refinements::Array::Ensurable

      extend Forwardable

      def_delegators :@object, :type, :text, :html, :label, :labeled?

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
      def initialize(html, info: {}, logical_path: nil)
        @object = StringDoc.new(html)
        @info, @logical_path = info, logical_path

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
      def find(*names, channel: nil)
        named = names.shift.to_sym
        found = bindings_with_name(named)

        unless channel.nil?
          combined_channel = Array.ensure(channel).join(":")

          found.select! do |node|
            if channel.nil?
              true
            else
              node.label(:combined_channel) == combined_channel || node.label(:combined_channel).end_with?(":" + combined_channel)
            end
          end
        end

        found.map! do |node|
          View.from_object(node)
        end

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
        bindings_with_name(named).each_with_object([]) { |node, arr|
          arr << View.from_object(node)
        }
      end

      # Finds a form with a binding matching +name+.
      #
      def form(name)
        if form_node = @object.find_significant_nodes(:form).find { |form| form.label(:binding) == name }
          Form.from_object(form_node)
        else
          nil
        end
      end

      # Returns all forms.
      #
      def forms
        @object.find_significant_nodes(:form).map { |form_node|
          Form.from_object(form_node)
        }
      end

      # Returns all view info when +key+ is +nil+, otherwise returns the value for +key+.
      #
      def info(key = nil)
        if key.nil?
          @info
        else
          @info.fetch(key.to_s, nil)
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
          if object.nil? || (object.respond_to?(:empty?) && object.empty?)
            remove
          else
            binding_props.each do |binding|
              unless object.value?(binding.label(:binding))
                binding.remove
              end
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
            binding_props.each do |binding|
              if object.include?(binding.label(:binding))
                value = if object.is_a?(Binder)
                  object.__content(binding.label(:binding), binding)
                else
                  object[binding.label(:binding)]
                end

                bind_value_to_node(value, binding)
                binding.set_label(:used, true)
              end
            end

            attributes[:"data-id"] = object[:id]
            self.object.set_label(:used, true)
          end
        end
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
        @object.significant?(:binding)
      end

      # Returns true if +self+ is a container.
      #
      def container?
        @object.significant?(:container)
      end

      # Returns true if +self+ is a partial.
      #
      def partial?
        @object.significant?(:partial)
      end

      # Returns true if +self+ is a form.
      #
      def form?
        @object.significant?(:form)
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
      def to_html(clean_bindings: true, clean_versions: true)
        if clean_bindings
          remove_unused_bindings
        end

        if clean_versions
          remove_unused_versions
        end

        @object.to_html
      end
      alias :to_s :to_html

      # @api private
      def binding_name
        label(:binding)
      end

      # @api private
      def all_binding_scopes
        @object.find_significant_nodes(:binding).select { |node|
          node.significant?(:binding_within) || node.label(:version) == :empty
        }
      end

      # @api private
      def binding_scopes
        @object.find_significant_nodes_without_descending(:binding).select { |node|
          node.significant?(:binding_within) || node.label(:version) == :empty
        }
      end

      # @api private
      def all_binding_props
        @object.find_significant_nodes(:binding).reject { |node|
          node.significant?(:binding_within)
        }
      end

      # @api private
      def binding_props
        @object.find_significant_nodes_without_descending(:binding).reject { |node|
          node.significant?(:binding_within)
        }
      end

      # @api private
      def find_partials(partials)
        @object.find_significant_nodes(:partial).each_with_object([]) { |partial_node, found_partials|
          if replacement = partials[partial_node.label(:partial)]
            found_partials << partial_node.label(:partial)
            found_partials.concat(replacement.find_partials(partials))
          end
        }
      end

      # @api private
      def mixin(partials)
        tap do
          @object.find_significant_nodes(:partial).each do |partial_node|
            if replacement = partials[partial_node.label(:partial)]
              partial_node.replace_internal(replacement.mixin(partials).object)
            end
          end
        end
      end

      # Thanks Dan! https://stackoverflow.com/a/30225093
      # @api private
      INFO_MERGER = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }

      # @api private
      def add_info(*infos)
        tap do
          infos.each do |info|
            @info.merge!(info, &INFO_MERGER)
          end
        end
      end

      protected

      def bind_value_to_node(value, node)
        tag = node.tagname
        return if StringDoc::Node.without_value?(tag)

        value = String(value)

        if StringDoc::Node.self_closing?(tag)
          node.attributes[:value] = ensure_html_safety(value) if node.attributes[:value].nil?
        else
          node.html = ensure_html_safety(value)
        end
      end

      def bindings_with_name(name)
        (binding_scopes + binding_props).select { |node|
          node.label(:binding) == name
        }
      end

      def remove_unused_bindings
        @object.find_significant_nodes(:binding).reject { |node|
          node.labeled?(:used)
        }.each(&:remove)
      end

      def remove_unused_versions
        versioned_nodes.each do |node_set|
          node_set.reject { |node|
            node.label(:version) == VersionedView::DEFAULT_VERSION
          }.each(&:remove)
        end
      end

      def versioned_nodes(nodes = object_nodes, versions = [])
        versions << nodes.select { |node|
          node.significant? && node.attributes.is_a?(StringDoc::Attributes) && node.labeled?(:version)
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
