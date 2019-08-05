# frozen_string_literal: true

require "forwardable"

require "string_doc/meta_node"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/support/class_state"
require "pakyow/support/safe_string"
require "pakyow/support/string_builder"

require "pakyow/presenter/presentable"

require "pakyow/presenter/presenters/endpoint"

module Pakyow
  module Presenter
    # Presents a view object with dynamic state in context of an app instance. In normal usage you
    # will be interacting with presenters rather than the {View} directly.
    #
    class Presenter
      extend Support::Makeable
      extend Support::ClassState
      class_state :__attached_renders, default: [], inheritable: true
      class_state :__global_options, default: {}, inheritable: true
      class_state :__presentation_logic, default: {}, inheritable: true
      class_state :__versioning_logic, default: {}, inheritable: true

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
      # @api private
      attr_reader :app

      def initialize(view, app:, presentables: {})
        @app, @view, @presentables = app, view, presentables
        @logger = Pakyow.logger
        @called = false
      end

      # Returns a presenter for a view binding.
      #
      # @see View#find
      def find(*names)
        result = if found_view = @view.find(*names)
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
      # @api private
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
      # @api private
      def forms
        @view.forms.map { |form|
          presenter_for(form)
        }
      end

      # Returns the component matching +name+.
      #
      def component(name)
        if found_component = @view.component(name)
          presenter_for(found_component)
        else
          nil
        end
      end

      # Returns all components.
      #
      # @api private
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
        @view.use(version)
        self
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
              @view.use(:empty); @view.object.set_label(:bound, true)
            else
              remove
            end
          else
            template = @view.soft_copy
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

              current = template.soft_copy
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

          set_binding_info(data)
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

            unless presenter.view.object.labeled?(:bound) || self.class.__presentation_logic.empty?
              self.class.__presentation_logic[presenter.view.channeled_binding_name].to_a.each do |presentation_logic|
                presenter.instance_exec(binder.object, &presentation_logic[:block])
              end
            end

            if presenter.view.is_a?(VersionedView)
              unless presenter.view.used? || self.class.__versioning_logic.empty?
                # Use global versions.
                #
                presenter.view.names.each do |version|
                  self.class.__versioning_logic[version]&.each do |logic|
                    if presenter.instance_exec(binder.object, &logic[:block])
                      presenter.use(version); break
                    end
                  end
                end
              end

              # If we still haven't used a version, use one implicitly.
              #
              unless presenter.view.used?
                presenter.use_implicit_version
              end

              # Implicitly use binding props.
              #
              presenter.view.binding_props.map { |binding_prop|
                binding_prop.label(:binding)
              }.uniq.each do |binding_prop_name|
                if found = presenter.view.find(binding_prop_name)
                  presenter_for(found).use_implicit_version unless found.used?
                end
              end
            end

            presenter.bind(binder)

            presenter.view.binding_scopes.uniq { |binding_scope|
              binding_scope.label(:binding)
            }.each do |binding_node|
              plural_binding_node_name = Support.inflector.pluralize(binding_node.label(:binding)).to_sym

              if nested_view = presenter.find(binding_node.label(:binding))
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
          binder_for_current_scope(data)
        end
      end

      def to_html(output = String.new)
        @view.object.to_html(output, context: self)
      end

      def to_s
        @view.to_s
      end

      def presenter_for(view, type: nil)
        if view.nil?
          nil
        else
          instance = self.class.new(
            view,
            app: @app,
            presentables: @presentables
          )

          type ||= view.object.label(:presenter_type)
          type ? type.new(instance) : instance
        end
      end

      # @api private
      def endpoint(name)
        found = []

        object.each_significant_node(:endpoint) do |endpoint_node|
          if endpoint_node.label(:endpoint) == name.to_sym
            found << endpoint_node
          end
        end

        if found.any?
          if found[0].is_a?(StringDoc::MetaNode)
            presenter_for(View.from_object(found[0]))
          else
            presenter_for(View.from_object(StringDoc::MetaNode.new(found)))
          end
        else
          nil
        end
      end

      # @api private
      def endpoint_action
        endpoint_action_node = object.find_first_significant_node(
          :endpoint_action
        ) || object

        presenter_for(View.from_object(endpoint_action_node))
      end

      # @api private
      def use_implicit_version
        case object
        when StringDoc::MetaNode
          if object.internal_nodes.all? { |node| node.labeled?(:version) && node.label(:version) != VersionedView::DEFAULT_VERSION }
            use(object.internal_nodes.first.label(:version))
          else
            use(:default)
          end
        else
          if versions.all? { |view| view.object.labeled?(:version) && view.object.label(:version) != VersionedView::DEFAULT_VERSION }
            use(versions.first.object.label(:version))
          else
            use(:default)
          end
        end
      end

      private

      def binder_for_current_scope(data)
        context = if plug = @view.label(:plug)
          @app.plug(plug[:name], plug[:instance])
        else
          @app
        end

        binder = context.state(:binder).find { |possible_binder|
          possible_binder.__object_name.name == @view.label(:binding)
        }

        unless binder
           binder = @app.isolated(:Binder)
           context = @app
        end

        binder.new(data, app: context)
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

            binding_view.object.set_label(:bound, true)
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

      def set_binding_info(data)
        object = if data.is_a?(Binder)
          data.object
        else
          data
        end

        if object && @view.object.labeled?(:binding)
          binding_info = {
            @view.object.label(:binding) => object[:id]
          }

          set_binding_info_for_node(@view.object, binding_info)

          @view.object.each_significant_node(:binding, descend: true) do |binding_node|
            set_binding_info_for_node(binding_node, binding_info)
          end

          @view.object.each_significant_node(:form, descend: true) do |form_node|
            set_binding_info_for_node(form_node, binding_info)
          end
        end
      end

      def set_binding_info_for_node(node, info)
        unless node.labeled?(:binding_info)
          node.set_label(:binding_info, {})
        end

        node.label(:binding_info).merge!(info)
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

        @view.object.each_significant_node(:endpoint, descend: true) do |endpoint_node|
          set_endpoint_params_for_node(endpoint_node, object)
        end
      end

      def set_endpoint_params_for_node(node, object)
        object = object.to_h

        endpoint_object = node.label(:endpoint_object)
        endpoint_params = node.label(:endpoint_params)

        if endpoint_object && endpoint_params
          endpoint_object.params.each do |param|
            param_string = param.to_s

            object.keys.each do |object_key|
              object_key_prefix = "#{object_key}_"
              if param_string.start_with?(object_key_prefix)
                set_endpoint_params_for_node(node, object[object_key])
                key = param_string.split(object_key_prefix, 2)[1].to_sym
                if object[object_key]&.include?(key)
                  endpoint_params[param] = object[object_key][key]; next
                end
              end
            end

            param_key_prefix = "#{@view.label(:binding)}_"
            if param_string.start_with?(param_key_prefix)
              key = param_string.split(param_key_prefix, 2)[1].to_sym
              if object.include?(key)
                endpoint_params[param] = object[key]; next
              end
            end

            if object.include?(param)
              endpoint_params[param] = object[param]
            end
          end
        end
      end

      def present?(key, object)
        !internal_presentable?(key) && (object_presents?(object, key) || plug_presents?(object, key))
      end

      def internal_presentable?(key)
        key.to_s.start_with?("__")
      end

      def object_presents?(object, key)
        key == plural_channeled_binding_name || key == singular_channeled_binding_name
      end

      def plug_presents?(object, key)
        key = key.to_s
        object.labeled?(:plug) &&
          key.start_with?(object.label(:plug)[:key]) &&
          # FIXME: Find a more performant way to do this
          #
          object_presents?(object, key.split("#{object.label(:plug)[:key]}.", 2)[1].to_sym)
      end

      class << self
        using Support::Refinements::String::Normalization

        attr_reader :path

        # @api private
        def make(path, **kwargs, &block)
          path = String.normalize_path(path)
          super(path, path: path, **kwargs, &block)
        end

        # Defines a render to attach to a node.
        #
        def render(*binding_path, node: nil, priority: :default, &block)
          if node && !node.is_a?(Proc)
            raise ArgumentError, "Expected `#{node.class}' to be a proc"
          end

          if binding_path.empty? && node.nil?
            node = -> { self }
          end

          @__attached_renders << {
            binding_path: binding_path,
            node: node,
            priority: priority,
            block: block
          }
        end

        # Defines a presentation block called when +binding_name+ is presented. If +channel+ is
        # provided, the block will only be called for that channel.
        #
        def present(binding_name, &block)
          (@__presentation_logic[binding_name.to_sym] ||= []) << {
            block: block
          }
        end

        # Defines a versioning block called when +version_name+ is presented.
        #
        def version(version_name, &block)
          (@__versioning_logic[version_name] ||= []) << {
            block: block
          }
        end

        # Attaches renders to a view's doc.
        #
        def attach(view)
          views_with_renders = {}

          renders = @__attached_renders.dup

          # Automatically present exposed values for this view. Doing this dynamically lets us
          # optimize. The alternative is to attach a render to the entire view, which is less
          # performant because the entire structure must be duped.
          #
          view.binding_scopes.map { |binding_node|
            {
              binding_path: [
                binding_node.label(:channeled_binding)
              ]
            }
          }.uniq.each do |binding_render|
            renders << {
              binding_path: binding_render[:binding_path],
              priority: :low,
              block: Proc.new {
                if object.labeled?(:binding) && !object.labeled?(:bound)
                  presentables.each do |key, value|
                    if present?(key, object)
                      present(value); break
                    end
                  end
                end
              }
            }
          end

          # Setup binding endpoints in a similar way to automatic presentation above.
          #
          Presenters::Endpoint.attach_to_node(view.object, renders)

          renders.each do |render|
            return_value = if node = render[:node]
              view.instance_exec(&node)
            else
              view.find(*render[:binding_path])
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

          views_with_renders.values.each do |view_with_renders, renders_for_view|
            attach_to_node = view_with_renders.object

            if attach_to_node.is_a?(StringDoc)
              attach_to_node = attach_to_node.find_first_significant_node(:html)
            end

            if attach_to_node
              renders_for_view.each do |render|
                attach_to_node.transform priority: render[:priority], &render_proc(view_with_renders, render, &render[:block])
              end
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

        def render_proc(_view, _render = nil, &block)
          Proc.new do |node, context, string|
            case node
            when StringDoc::MetaNode
              if node.nodes.any?
                returning = node
                presenter = context.presenter_for(
                  VersionedView.new(View.from_object(node))
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

            presenter.instance_exec(node, context, string, &block); returning
          rescue => error
            if presenter.app.config.presenter.features.streaming
              Pakyow.logger.houston(error)

              presenter.clear
              presenter.attributes[:class] << :"render-failed"
              presenter.view.object.set_label(:failed, true)
              presenter.object
            else
              raise error
            end
          end
        end

        def relate_value_to_render(value, render, state)
          final_value = case value
          when View, VersionedView
            value
          else
            View.new(value.to_s)
          end

          # Group the renders by node and view type.
          #
          (state["#{final_value.object.object_id}::#{final_value.class}"] ||= [final_value, []])[1] << render
        end
      end
    end
  end
end
