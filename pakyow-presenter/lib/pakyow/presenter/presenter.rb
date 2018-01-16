# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"

require "pakyow/presenter/presentable"
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

      def initialize(view, binders: [], paths: nil, embed_templates: true)
        @view, @binders, @paths, @embed_templates = view, binders, paths, embed_templates

        set_title_from_info
        set_form_field_names

        if embed_templates
          create_embedded_templates
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
          @view.transform(data)
        end
      end

      # Binds +data+ to the view, using the appropriate binder if available.
      #
      def bind(data)
        tap do
          if binder = binder_for_current_scope
            bind_binder_to_view(binder.new(data), @view)
          else
            @view.bind(data)
          end
        end
      end

      # Transforms the view to match +data+, then binds.
      #
      # @see View#present
      #
      def present(data)
        tap do
          @view.transform(data) do |view, object|
            presenter = presenter_for(view)
            yield view, object if block_given?
            presenter.bind(object)

            view.binding_scopes.each do |binding_node|
              presenter.find(binding_node.name).present(object[binding_node.name])
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
        type.new(view, binders: binders, paths: @paths, embed_templates: @embed_templates)
      end

      def binder_for_current_scope
        binders.find { |binder|
          binder.__class_name.name == @view.name
        }
      end

      def bind_binder_to_view(binder, view)
        bindable = binder.object

        view.binding_props.each do |binding|
          value = binder[binding.name]

          if value.is_a?(BindingParts)
            next unless binding_view = view.find(binding.name)

            value.accept(*binding_view.label(:include).to_s.split(" "))
            value.reject(*binding_view.label(:exclude).to_s.split(" "))

            bindable[binding.name] = value.content if value.content?

            value.non_content_parts.each_pair do |key, value_part|
              binding_view.attrs[key] = value_part
            end
          else
            bindable[binding.name] = value
          end
        end

        view.bind(bindable)
      end

      def set_title_from_info
        if @view && title_from_info = @view.info(:title)
          self.title = title_from_info
        end
      end

      def set_form_field_names
        @view.object.find_significant_nodes(:form).each do |form_node|
          form_node.children.find_significant_nodes(:binding).each do |binding_node|
            binding_node.attributes[:name] ||= "#{form_node.name}[#{binding_node.name}]"
          end
        end
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
          duped_node_with_binding.instance_variable_set(:@type, nil)
          duped_node_with_binding.instance_variable_set(:@name, nil)
          template.append(duped_node_with_binding)
          node_with_binding.after(template)
        end
      end
    end
  end
end
