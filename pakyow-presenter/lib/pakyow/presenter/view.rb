# frozen_string_literal: true

require "forwardable"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/indifferentize"
require "pakyow/support/inflector"
require "pakyow/support/safe_string"

require_relative "../../string_doc"

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
          instance = if object.is_a?(StringDoc::Node) && object.labeled?(:view_type)
            object.label(:view_type).allocate
          else
            allocate
          end

          instance.instance_variable_set(:@object, object)
          instance.instance_variable_set(:@info, {})
          instance.instance_variable_set(:@logical_path, nil)

          if object.respond_to?(:attributes)
            instance.attributes = object.attributes
          else
            instance.instance_variable_set(:@attributes, nil)
          end

          instance
        end

        # @api private
        def from_view_or_string(view_or_string)
          case view_or_string
          when View, VersionedView
            view_or_string
          else
            View.new(Support::SafeStringHelpers.ensure_html_safety(view_or_string.to_s))
          end
        end
      end

      include Support::SafeStringHelpers

      using Support::Indifferentize
      using Support::Refinements::Array::Ensurable

      extend Forwardable

      def_delegators :@object, :type, :text, :html, :label, :labeled?

      # The object responsible for transforming and rendering the underlying document or node.
      #
      # @api private
      attr_accessor :object

      # The logical path to the view template.
      #
      attr_reader :logical_path

      # Creates a view with +html+.
      #
      def initialize(html, info: {}, logical_path: nil)
        @object = StringDoc.new(html)
        @info, @logical_path = Support::IndifferentHash.deep(info), logical_path

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

      # @api private
      def soft_copy
        instance = self.class.allocate

        instance.instance_variable_set(:@info, @info.dup)

        new_object = @object.soft_copy
        instance.instance_variable_set(:@object, new_object)

        if new_object.respond_to?(:attributes)
          instance.attributes = new_object.attributes
        else
          instance.instance_variable_set(:@attributes, nil)
        end

        instance
      end

      # Finds a view binding by name. When passed more than one value, the view will
      # be traversed through each name. Returns a {VersionedView}.
      #
      def find(*names)
        if names.any?
          named = names.shift.to_sym
          found = each_binding(named).map(&:itself)

          result = if names.empty? && !found.empty? # found everything; wrap it up
            if found[0].is_a?(StringDoc::MetaNode)
              VersionedView.new(View.from_object(found[0]))
            else
              VersionedView.new(View.from_object(StringDoc::MetaNode.new(found)))
            end
          elsif !found.empty? && names.count > 0 # descend further
            View.from_object(found[0]).find(*names)
          end

          if result && block_given?
            yield result
          end

          result
        end
      end

      # Finds all view bindings by name, returning an array of {View} objects.
      #
      # @api private
      def find_all(named)
        each_binding(named).map { |node|
          View.from_object(node)
        }
      end

      # Finds a form with a binding matching +name+.
      #
      def form(name)
        @object.each_significant_node(:form) do |form_node|
          return Views::Form.from_object(form_node) if form_node.label(:binding) == name
        end

        nil
      end

      # Returns all forms.
      #
      # @api private
      def forms
        @object.each_significant_node(:form, descend: true).map { |node|
          Views::Form.from_object(node)
        }
      end

      # Finds a component matching +name+.
      #
      def component(name, renderable: false)
        name = name.to_sym
        components(renderable: renderable).find { |component|
          component.object.label(:components).any? { |possible_component|
            possible_component[:name] == name
          }
        }
      end

      # Returns all components.
      #
      # @api private
      def components(renderable: false)
        @object.each_significant_node_without_descending_into_type(:component, descend: true).select { |node|
          !renderable || node.label(:components).any? { |component| component[:renderable] }
        }.map { |node|
          View.from_object(node)
        }
      end

      # Returns all view info when +key+ is +nil+, otherwise returns the value for +key+.
      #
      def info(key = nil)
        if key.nil?
          @info
        else
          @info.fetch(key, nil)
        end
      end

      # Returns a view for the +<head>+ node.
      #
      def head
        if (head_node = @object.find_first_significant_node(:head))
          View.from_object(head_node)
        end
      end

      # Returns a view for the +<body>+ node.
      #
      def body
        if (body_node = @object.find_first_significant_node(:body))
          View.from_object(body_node)
        end
      end

      # Returns a view for the +<title>+ node.
      #
      def title
        if (title_node = @object.find_first_significant_node(:title))
          View.from_object(title_node)
        end
      end

      # Yields +self+.
      #
      def with
        yield self
        self
      end

      # Transforms +self+ to match structure of +object+.
      #
      def transform(object)
        if object.nil? || (object.respond_to?(:empty?) && object.empty?)
          remove
        else
          removals = []
          each_binding_prop(descend: false) do |binding|
            binding_name = if binding.significant?(:multipart_binding)
              binding.label(:binding_prop)
            else
              binding.label(:binding)
            end

            unless object.present?(binding_name)
              removals << binding
            end
          end

          removals.each(&:remove)
        end

        yield self, object if block_given?

        self
      end

      # Binds a single object.
      #
      def bind(object)
        unless object.nil?
          each_binding_prop do |binding|
            binding_name = if binding.significant?(:multipart_binding)
              binding.label(:binding_prop)
            else
              binding.label(:binding)
            end

            if object.include?(binding_name)
              value = if object.is_a?(Binder)
                object.__content(binding_name, binding)
              else
                object[binding_name]
              end

              bind_value_to_node(value, binding)
              binding.set_label(:bound, true)
            end
          end

          attributes[:"data-id"] = object[:id]
          self.object.set_label(:bound, true)
        end

        self
      end

      # Appends a view or string to +self+.
      #
      def append(view_or_string)
        @object.append(self.class.from_view_or_string(view_or_string).object)
        self
      end

      # Prepends a view or string to +self+.
      #
      def prepend(view_or_string)
        @object.prepend(self.class.from_view_or_string(view_or_string).object)
        self
      end

      # Inserts a view or string after +self+.
      #
      def after(view_or_string)
        @object.after(self.class.from_view_or_string(view_or_string).object)
        self
      end

      # Inserts a view or string before +self+.
      #
      def before(view_or_string)
        @object.before(self.class.from_view_or_string(view_or_string).object)
        self
      end

      # Replaces +self+ with a view or string.
      #
      def replace(view_or_string)
        @object.replace(self.class.from_view_or_string(view_or_string).object)
        self
      end

      # Removes +self+.
      #
      def remove
        @object.remove
        self
      end

      # Removes +self+'s children.
      #
      def clear
        @object.clear
        self
      end

      # Safely sets the html value of +self+.
      #
      def html=(html)
        @object.html = ensure_html_safety(html.to_s)
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
      attr_reader :attributes
      alias_method :attrs, :attributes

      # Wraps +attributes+ in a {Attributes} instance.
      #
      def attributes=(attributes)
        @attributes = Attributes.new(attributes)
      end
      alias_method :attrs=, :attributes=

      # Returns the version name for +self+.
      #
      def version
        (label(:version) || VersionedView::DEFAULT_VERSION).to_sym
      end

      # Converts +self+ to html, rendering the view.
      #
      def to_html
        @object.to_html
      end

      def to_s
        @object.to_s
      end

      # @api private
      def binding_name
        label(:binding)
      end

      # @api private
      def singular_binding_name
        label(:singular_binding)
      end

      # @api private
      def plural_binding_name
        label(:plural_binding)
      end

      # @api private
      def channeled_binding_name
        label(:channeled_binding)
      end

      # @api private
      def plural_channeled_binding_name
        label(:plural_channeled_binding)
      end

      # @api private
      def singular_channeled_binding_name
        label(:singular_channeled_binding)
      end

      # @api private
      def each_binding_scope(descend: false)
        return enum_for(:each_binding_scope, descend: descend) unless block_given?

        method = if descend
          :each_significant_node
        else
          :each_significant_node_without_descending_into_type
        end

        @object.send(method, :binding, descend: descend) do |node|
          if binding_scope?(node)
            yield node
          end
        end
      end

      # @api private
      def each_binding_prop(descend: false)
        return enum_for(:each_binding_prop, descend: descend) unless block_given?

        if (@object.is_a?(StringDoc::Node) || @object.is_a?(StringDoc::MetaNode)) && @object.significant?(:multipart_binding)
          yield @object
        else
          method = if descend
            :each_significant_node
          else
            :each_significant_node_without_descending_into_type
          end

          @object.send(method, :binding, descend: descend) do |node|
            if binding_prop?(node)
              yield node
            end
          end
        end
      end

      # @api private
      def each_binding(name)
        return enum_for(:each_binding, name) unless block_given?

        each_binding_scope do |node|
          if node.label(:channeled_binding) == name
            yield node
          end
        end

        each_binding_prop do |node|
          if (node.significant?(:multipart_binding) && node.label(:binding_prop) == name) || (!node.significant?(:multipart_binding) && node.label(:binding) == name)
            yield node
          end
        end
      end

      # @api private
      def binding_scopes(descend: false)
        each_binding_scope(descend: descend).map(&:itself)
      end

      # @api private
      def binding_props(descend: false)
        each_binding_prop(descend: descend).map(&:itself)
      end

      # @api private
      def binding_scope?(node)
        node.significant?(:binding) && (node.significant?(:binding_within) || node.significant?(:multipart_binding) || node.label(:version) == :empty)
      end

      # @api private
      def binding_prop?(node)
        node.significant?(:binding) && node.label(:version) != :empty && (!node.significant?(:binding_within) || node.significant?(:multipart_binding))
      end

      # @api private
      def find_partials(partials, found = [])
        @object.each_significant_node(:partial, descend: true) do |node|
          if (replacement = partials[node.label(:partial)])
            found << node.label(:partial)
            replacement.find_partials(partials, found)
          end
        end

        found
      end

      # @api private
      def mixin(partials)
        @object.each_significant_node(:partial, descend: true) do |partial_node|
          if (replacement = partials[partial_node.label(:partial)])
            partial_node.replace(replacement.mixin(partials).object)
          end
        end

        self
      end

      # @api private
      def add_info(*infos)
        infos.each do |info|
          # Thanks Dan! https://stackoverflow.com/a/30225093
          #
          @info.merge!(Support::IndifferentHash.deep(info)) do |_, v1, v2|
            if Support::IndifferentHash === v1 && Support::IndifferentHash === v2
              v1.merge(v2, &merger)
            elsif Array === v1 && Array === v2
              v1 | v2
            else
              [:undefined, nil, :nil].include?(v2) ? v1 : v2
            end
          end
        end

        self
      end

      # @api private
      def channeled_binding_scope?(scope)
        binding_scopes.select { |node|
          node.label(:binding) == scope
        }.any? { |node|
          node.label(:channel).any?
        }
      end

      private

      def bind_value_to_node(value, node)
        tag = node.tagname
        unless StringDoc::Node.without_value?(tag)
          value = String(value)

          if StringDoc::Node.self_closing?(tag)
            node.attributes[:value] = ensure_html_safety(value) if node.attributes[:value].nil?
          else
            node.html = ensure_html_safety(value)
          end
        end
      end
    end
  end
end
