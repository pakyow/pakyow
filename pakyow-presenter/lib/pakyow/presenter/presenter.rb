# frozen_string_literal: true

require "forwardable"

require "string_doc/meta_node"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/support/class_state"
require "pakyow/support/safe_string"
require "pakyow/support/string_builder"

require "pakyow/presenter/presentable"

module Pakyow
  module Presenter
    # Presents a view object with dynamic state in context of an app instance. In normal usage you
    # will be interacting with presenters rather than the {View} directly.
    #
    class Presenter
      extend Support::Makeable
      extend Support::ClassState
      class_state :__version_logic, default: {}, inheritable: true
      class_state :__attached_renders, default: [], inheritable: true
      class_state :__global_options, default: {}, inheritable: true

      using Support::Refinements::Array::Ensurable

      include Support::SafeStringHelpers

      include Presentable

      # The view object being presented.
      #
      attr_reader :view

      # The logger object.
      #
      attr_reader :logger

      # Values to be presented.
      #
      attr_reader :presentables

      # The app object.
      #
      attr_reader :app

      def initialize(view, app:, presentables: {})
        @app, @view, @presentables = app, view, presentables
        @logger = Pakyow.logger
        @called = false
      end

      # Returns a presenter for a view binding.
      #
      # @see View#find
      def find(*names, channel: nil)
        result = if found_view = @view.find(*names, channel: channel)
          presenter_for(found_view)
        else
          nil
        end

        if result && block_given?
          yield result
        end

        result
      end

      # Returns an array of presenters, one for each view binding.
      #
      # @see View#find_all
      def find_all(*names)
        @view.find_all(*names).map { |view|
          presenter_for(view)
        }
      end

      # Returns the named form from the view being presented.
      #
      def form(name)
        if found_form = @view.form(name)
          presenter_for(found_form)
        else
          nil
        end
      end

      # Returns all forms.
      #
      def forms
        @view.forms.map { |form|
          presenter_for(form)
        }
      end

      # Returns all components.
      #
      def components(renderable: false)
        @view.components(renderable: renderable).map { |component|
          presenter_for(component)
        }
      end

      # Returns the title value from the view being presented.
      #
      def title
        @view.title&.text
      end

      # Sets the title value on the view.
      #
      def title=(value)
        unless @view.title
          if head_view = @view.head
            title_view = View.new("<title></title>")
            head_view.append(title_view)
          end
        end

        @view.title&.html = strip_tags(value)
      end

      # Uses the view matching +version+, removing all other versions.
      #
      def use(version)
        presenter_for(@view.use(version))
      end

      # Returns a presenter for the view matching +version+.
      #
      def versioned(version)
        presenter_for(@view.versioned(version))
      end

      # Yields +self+.
      #
      def with
        tap do
          yield self
        end
      end

      # Transforms the view to match +data+.
      #
      # @see View#transform
      #
      def transform(data, yield_binder = false)
        tap do
          data = Array.ensure(data).reject(&:nil?)

          if data.respond_to?(:empty?) && data.empty?
            if @view.is_a?(VersionedView) && @view.version?(:empty)
              @view.use(:empty)
            else
              remove
            end
          else
            template = @view.dup
            insertable = @view
            current = @view

            data.each do |object|
              binder = binder_or_data(object)

              current.transform(binder)

              if block_given?
                yield presenter_for(current), yield_binder ? binder : object
              end

              unless current.equal?(@view)
                insertable.after(current)
                insertable = current
              end

              current = template.dup
            end
          end
        end
      end

      # Binds +data+ to the view, using the appropriate binder if available.
      #
      def bind(data)
        tap do
          data = binder_or_data(data)

          if data.is_a?(Binder)
            bind_binder_to_view(data, @view)
          else
            @view.bind(data)
          end

          set_endpoint_params(data)
        end
      end

      # Transforms the view to match +data+, then binds, using the appropriate binder if available.
      #
      # @see View#present
      #
      def present(data)
        tap do
          transform(data, true) do |presenter, binder|
            if block_given?
              yield presenter, binder.object
            end

            presenter.bind(binder)

            presenter.view.binding_scopes(descend: false).uniq { |binding_scope|
              binding_scope.label(:binding)
            }.each do |binding_node|
              plural_binding_node_name = Support.inflector.pluralize(binding_node.label(:binding)).to_sym

              nested_view = presenter.find(binding_node.label(:binding))
              if binder.object.include?(binding_node.label(:binding))
                nested_view.present(binder.object[binding_node.label(:binding)])
              elsif binder.object.include?(plural_binding_node_name)
                nested_view.present(binder.object[plural_binding_node_name])
              else
                nested_view.remove
              end
            end
          end
        end
      end

      # @see View#append
      #
      def append(view)
        tap do
          @view.append(view)
        end
      end

      # @see View#prepend
      #
      def prepend(view)
        tap do
          @view.prepend(view)
        end
      end

      # @see View#after
      #
      def after(view)
        tap do
          @view.after(view)
        end
      end

      # @see View#before
      #
      def before(view)
        tap do
          @view.before(view)
        end
      end

      # @see View#replace
      #
      def replace(view)
        tap do
          @view.replace(view)
        end
      end

      # @see View#remove
      #
      def remove
        tap do
          @view.remove
        end
      end

      # @see View#clear
      #
      def clear
        tap do
          @view.clear
        end
      end

      # Returns true if +self+ equals +other+.
      #
      def ==(other)
        other.is_a?(self.class) && @view == other.view
      end

      def method_missing(name, *args, &block)
        if @view.respond_to?(name)
          value = @view.public_send(name, *args, &block)

          if value.equal?(@view)
            self
          else
            value
          end
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        @view.respond_to?(name, include_private) || super
      end

      # @api private
      def wrap_data_in_binder(data)
        if data.is_a?(Binder)
          data
        else
          (binder_for_current_scope || @app.isolated(:Binder)).new(data, app: @app)
        end
      end

      def to_html(output = String.new)
        @view.object.to_html(output, context: self)
      end
      alias to_s to_html

      def presenter_for(view, type: view&.label(:presenter_type))
        if view.nil?
          nil
        else
          instance = self.class.new(
            view,
            app: @app,
            presentables: @presentables
          )

          type ? type.new(instance) : instance
        end
      end

      private

      def binder_for_current_scope
        @app.state(:binder).find { |binder|
          binder.__object_name.name == @view.label(:binding)
        }
      end

      def bind_binder_to_view(binder, view)
        view.each_binding_prop do |binding|
          value = binder.__value(binding.label(:binding))
          if value.is_a?(BindingParts) && binding_view = view.find(binding.label(:binding))
            value.accept(*binding_view.label(:include).to_s.split(" "))
            value.reject(*binding_view.label(:exclude).to_s.split(" "))

            value.non_content_values(binding_view).each_pair do |key, value_part|
              binding_view.attrs[key] = value_part
            end

            binding_view.object.set_label(:used, true)
          end
        end

        binder.binding!
        view.bind(binder)
      end

      def binder_or_data(data)
        if data.nil? || data.is_a?(Array) || data.is_a?(Binder)
          data
        else
          wrap_data_in_binder(data)
        end
      end

      def set_endpoint_params(data)
        object = if data.is_a?(Binder)
          data.object
        else
          data
        end

        if @view.object.labeled?(:endpoint)
          set_endpoint_params_for_node(@view.object, object)
        end

        @view.object.each_significant_node(:endpoint) do |endpoint_node|
          set_endpoint_params_for_node(endpoint_node, object)
        end
      end

      def set_endpoint_params_for_node(node, object)
        endpoint_object = node.label(:endpoint_object)
        endpoint_params = node.label(:endpoint_params)

        if endpoint_object && endpoint_params
          endpoint_object.params.each do |param|
            if param.to_s.end_with?("_id")
              type = param.to_s.split("_id")[0].to_sym
              if type == @view.label(:binding) && object.key?(:id)
                endpoint_params[param] = object[:id]
                next
              end
            end

            if object.key?(param)
              endpoint_params[param] = object[param]
            end
          end
        end
      end

      class << self
        using Support::Refinements::String::Normalization

        attr_reader :path

        def make(path, **kwargs, &block)
          path = String.normalize_path(path)
          super(path, path: path, **kwargs, &block)
        end

        # Defines a render to attach to a node.
        #
        def render(binding_name = nil, channel: nil, node: nil, priority: :default, &block)
          if node && !node.is_a?(Proc)
            raise ArgumentError, "Expected `#{node.class}' to be a proc"
          end

          @__attached_renders << {
            binding_name: binding_name,
            channel: channel,
            node: node,
            priority: priority,
            block: block
          }
        end

        # Attaches renders to a view's doc.
        #
        def attach(view)
          views_with_renders = {}

          @__attached_renders.each do |render|
            return_value = if node = render[:node]
              view.instance_exec(&node)
            else
              view.find(render[:binding_name], channel: render[:channel])
            end

            case return_value
            when Array
              return_value.each do |each_value|
                relate_value_to_render(each_value, render, views_with_renders)
              end
            when View, VersionedView
              relate_value_to_render(return_value, render, views_with_renders)
            end
          end

          views_with_renders.values.each do |view_with_renders, renders|
            attach_to_node = case view_with_renders
            when VersionedView
              StringDoc::MetaNode.new(view_with_renders.versions.map(&:object))
            when View
              view_with_renders.object
            end

            renders.each do |render|
              attach_to_node.transform priority: render[:priority], &render_proc(view_with_renders, &render[:block])
            end
          end
        end

        # Defines options attached to a form binding.
        #
        def options_for(form_binding, field_binding, options = nil, &block)
          form_binding = form_binding.to_sym
          field_binding = field_binding.to_sym

          @__global_options[form_binding] ||= {}
          @__global_options[form_binding][field_binding] = {
            options: options,
            block: block
          }
        end

        private

        def render_proc(view, &block)
          Proc.new do |node, context, string|
            case node
            when StringDoc::MetaNode
              if node.nodes.any?
                returning = node
                presenter = context.presenter_for(
                  VersionedView.new(node.nodes.map { |n| View.from_object(n) })
                )
              else
                next node
              end
            when StringDoc::Node
              returning = StringDoc.empty
              returning.append(node)
              presenter = context.presenter_for(
                View.from_object(node)
              )
            end

            presenter.instance_exec(string, &block); returning
          rescue => error
            Pakyow.logger.houston(error)

            presenter.clear
            presenter.attributes[:class] << :"render-failed"
            presenter.view.object.set_label(:failed, true)
            presenter
          end
        end

        def relate_value_to_render(value, render, state)
          final_value = case value
          when View, VersionedView
            value
          else
            View.new(value.to_s)
          end

          state_for_final_value = state[final_value.object.object_id] ||= [final_value, []]
          state_for_final_value[1] << render
        end
      end
    end
  end
end
