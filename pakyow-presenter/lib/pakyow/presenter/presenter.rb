# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"

require "pakyow/presenter/exceptions"
require "pakyow/presenter/renderer"

module Pakyow
  module Presenter
    # Presents a view object. Performs queries for view data. Understands binders / formatters.
    # Does not have access to the session, request, etc; only what is exposed to it from the route.
    # State is passed explicitly to the presenter, exposed by calling the `presentable` helper.
    #
    # In normal usage you will be interacting with presenters rather than the {View} directly.
    #
    class Presenter
      extend Forwardable

      include Support::SafeStringHelpers

      # The view object being presented.
      #
      attr_reader :view
      attr_reader :binders

      # @!method attributes
      #   Delegates to {view}.
      #   @see View#attributes
      #
      # @!method attrs
      #   Delegates to {view}.
      #   @see View#attrs
      #
      # @!method html=
      #   Delegates to {view}.
      #   @see View#html=
      #
      # @!method html
      #   Delegates to {view}.
      #   @see View#html
      #
      # @!method text
      #   Delegates to {view}.
      #   @see View#text
      #
      # @!method binding?
      #   Delegates to {view}.
      #   @see View#binding?
      #
      # @!method container?
      #   Delegates to {view}.
      #   @see View#container?
      #
      # @!method partial?
      #   Delegates to {view}.
      #   @see View#partial?
      #
      # @!method component?
      #   Delegates to {view}.
      #   @see View#component?
      #
      # @!method form?
      #   Delegates to {view}.
      #   @see View#form?
      #
      # @!method to_html
      #   Delegates to {view}.
      #   @see View#to_html
      #
      # @!method to_s
      #   Delegates to {view}.
      #   @see View#to_s
      #
      # @!method version
      #   Delegates to {view}.
      #   @see View#version
      #
      # @!method info
      #   Delegates to {view}.
      #   @see View#info
      #
      # @!method use
      #   Delegates to {view}.
      #   @see VersionedView#use
      #
      # @!method versioned
      #   Delegates to {view}.
      #   @see VersionedView#versioned
      def_delegators :@view, :attributes, :attrs, :html=, :html, :text, :binding?, :container?, :partial?, :component?, :form?, :version, :info, :to_html, :to_s, :use, :versioned

      def initialize(view, binders: [], endpoints: nil, current_endpoint: {}, prototype: false, embed_templates: false)
        @view, @binders, @endpoints, @current_endpoint, @embed_templates = view, binders, endpoints, current_endpoint, embed_templates

        set_title_from_info
        setup_form_field_names

        unless prototype
          remove_prototype_nodes
        end

        if embed_templates
          create_embedded_templates
        end

        if endpoints
          setup_non_contextual_endpoints
        end
      end

      # Returns a presenter for a view binding.
      #
      # @see View#find
      def find(*names)
        if found_view = @view.find(*names)
          presenter_for(found_view)
        else
          nil
        end
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
          presenter_for(found_form, type: FormPresenter)
        else
          nil
        end
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

      # Returns an array of components matching +name+.
      #
      def components(name)
        @view.components(name).map { |view|
          presenter_for(view)
        }
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
      def transform(data)
        tap do
          data = Array.ensure(data)

          if ((data.respond_to?(:empty?) && data.empty?) || data.nil?)
            if @view.is_a?(VersionedView) && @view.version?(:empty)
              @view.use(:empty)
            else
              remove
            end
          else
            template = @view.dup
            insertable = @view
            local = @view

            data.each do |object|
              object = binder_or_data(object)

              local.transform(object)

              if block_given?
                yield presenter_for(local), object
              end

              unless local.equal?(@view)
                insertable.after(local)
                insertable = local
              end

              local = template.dup
            end
          end
        end
      end

      # Binds +data+ to the view, using the appropriate binder if available.
      #
      def bind(data)
        tap do
          if data = binder_or_data(data)
            setup_binding_endpoints(data.object)
          end

          if data.is_a?(Binder)
            bind_binder_to_view(data, @view)
          else
            @view.bind(data)
          end
        end
      end

      # Transforms the view to match +data+, then binds, using the appropriate binder if available.
      #
      # @see View#present
      #
      def present(data)
        tap do
          transform(data) do |presenter, binder|
            yield presenter, binder.object if block_given?
            presenter.bind(binder)

            presenter.view.binding_scopes.each do |binding_node|
              plural_binding_node_name = Support.inflector.pluralize(binding_node.name).to_sym

              data = if binder.object.include?(binding_node.name)
                binder.object[binding_node.name]
              elsif binder.object.include?(plural_binding_node_name)
                binder.object[plural_binding_node_name]
              else
                nil
              end

              presenter.find(binding_node.name).present(data)
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
        other.is_a?(Presenter) && @view == other.view
      end

      private

      def presenter_for(view, type: Presenter)
        type.new(view, binders: binders, endpoints: @endpoints, current_endpoint: @current_endpoint)
      end

      def binder_for_current_scope
        binders.find { |binder|
          binder.__class_name.name == @view.name
        }
      end

      def bind_binder_to_view(binder, view)
        view.binding_props.each do |binding|
          value = binder.value(binding.name)
          if value.is_a?(BindingParts) && binding_view = view.find(binding.name)
            value.accept(*binding_view.label(:include).to_s.split(" "))
            value.reject(*binding_view.label(:exclude).to_s.split(" "))

            value.non_content_parts.each_pair do |key, value_part|
              binding_view.attrs[key] = value_part
            end
          end
        end

        binder.binding!
        view.bind(binder)
      end

      def binder_or_data(data)
        if data.nil? || data.is_a?(Array) || data.is_a?(Binder)
          data
        else
          (binder_for_current_scope || Binder).new(data).tap do |binder|
            if binder_local_endpoints = @endpoints
              binder.define_singleton_method :path do |*args|
                binder_local_endpoints.path(*args)
              end

              binder.define_singleton_method :path_to do |*args|
                binder_local_endpoints.path_to(*args)
              end
            end
          end
        end
      end

      def set_title_from_info
        if @view && title_from_info = @view.info(:title)
          self.title = title_from_info
        end
      end

      def setup_form_field_names
        @view.object.find_significant_nodes(:form).each do |form_node|
          form_node.children.find_significant_nodes(:binding).each do |binding_node|
            binding_node.attributes[:name] ||= "#{form_node.name}[#{binding_node.name}]"
          end
        end
      end

      def remove_prototype_nodes
        @view.object.find_significant_nodes(:prototype, with_children: true).each(&:remove)
      end

      def create_embedded_templates
        @view.binding_scopes.each do |node_with_binding|
          version = node_with_binding.label(:version) || VersionedView::DEFAULT_VERSION
          template = StringDoc.new("<script type=\"text/template\" data-version=\"#{version}\"></script>").nodes.first

          node_with_binding.attributes.each do |attribute, value|
            next unless attribute.to_s.start_with?("data")
            template.attributes[attribute] = value
          end

          duped_node_with_binding = node_with_binding.dup
          duped_node_with_binding.with_children.each do |node|
            node.instance_variable_set(:@type, nil)
            node.instance_variable_set(:@name, nil)
          end
          template.append(duped_node_with_binding)
          node_with_binding.after(template)
        end
      end

      def setup_non_contextual_endpoints
        setup_endpoints(@view.object.find_significant_nodes(:endpoint, with_children: true))
      end

      def setup_binding_endpoints(object)
        if object.include?(:id)
          object[:"#{Support.inflector.singularize(@view.name)}_id"] = object[:id]
        end

        setup_endpoints(
          @view.object.find_significant_nodes(
            :binding_endpoint, with_children: true
          ).concat(@view.object.find_significant_nodes(
            :binding, with_children: true
            ).select { |binding_node|
              binding_node.labeled?(:endpoint)
            }
          ), object)
      end

      def setup_endpoints(nodes, params = @current_endpoint[:params] || {})
        nodes.each do |endpoint_node|
          endpoint_view = View.from_object(endpoint_node)
          endpoint_parts = endpoint_node.label(:endpoint).to_s.split("#").map(&:to_sym)

          endpoint_action_node = find_endpoint_action_node(endpoint_node)

          if endpoint_parts.last == :remove
            wrap_endpoint_for_removal(endpoint_view, endpoint_parts, params)
          elsif endpoint_action_node.tagname == "a"
            setup_endpoint_for_anchor(endpoint_view, View.from_object(endpoint_action_node), endpoint_parts, params)
          end
        end
      end

      def wrap_endpoint_for_removal(endpoint_view, endpoint_parts, params)
        delete_form = View.new(
          <<~HTML
          <form action="#{@endpoints.path_to(*endpoint_parts, params)}" method="post" data-ui="confirm">
            <input type="hidden" name="_method">

            #{endpoint_view}
          </form>
          HTML
        )

        endpoint_view.replace(delete_form)
      end

      def setup_endpoint_for_anchor(endpoint_view, endpoint_action_view, endpoint_parts, params)
        if path = @endpoints.path_to(*endpoint_parts, params)
          endpoint_action_view.attributes[:href] = path
        end

        if endpoint_action_view.attributes.has?(:href) && @current_endpoint[:path].to_s.start_with?(endpoint_action_view.attributes[:href])
          endpoint_view.attributes[:class].add(:active)
        end
      end

      def find_endpoint_action_node(endpoint_node)
        if action_node = endpoint_node.find_significant_nodes(:endpoint_action, with_children: false)[0]
          action_node
        else
          endpoint_node
        end
      end
    end
  end
end
