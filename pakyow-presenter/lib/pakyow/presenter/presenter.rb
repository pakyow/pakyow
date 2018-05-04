# frozen_string_literal: true

require "forwardable"

require "pakyow/support/safe_string"
require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/presenter/exceptions"
require "pakyow/presenter/renderer"

require "pakyow/presenter/behavior/endpoints"
require "pakyow/presenter/behavior/prototype"
require "pakyow/presenter/behavior/templates"
require "pakyow/presenter/behavior/modes"

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

      using Support::Refinements::Array::Ensurable

      include Support::SafeStringHelpers

      include Behavior::Endpoints
      include Behavior::Prototype
      include Behavior::Templates
      include Behavior::Modes

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

      def initialize(view, binders: [])
        @view, @binders = view, binders

        set_title_from_info
        setup_form_field_names
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
          data = Array.ensure(data).compact

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
          data = binder_or_data(data)

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
              plural_binding_node_name = Support.inflector.pluralize(binding_node.label(:binding)).to_sym

              data = if binder.object.include?(binding_node.label(:binding))
                binder.object[binding_node.label(:binding)]
              elsif binder.object.include?(plural_binding_node_name)
                binder.object[plural_binding_node_name]
              else
                nil
              end

              presenter.find(binding_node.label(:binding)).present(data)
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
        type.new(view, binders: @binders)
      end

      def binder_for_current_scope
        expected_binder_name = @view.label(:binding).to_s.split(":")[0].to_sym

        binders.find { |binder|
          binder.__class_name.name == expected_binder_name
        }
      end

      def bind_binder_to_view(binder, view)
        view.binding_props.each do |binding|
          value = binder.value(binding.label(:binding))
          if value.is_a?(BindingParts) && binding_view = view.find(binding.label(:binding))
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
          wrap_data_in_binder(data)
        end
      end

      def wrap_data_in_binder(data)
        (binder_for_current_scope || Binder).new(data)
      end

      def set_title_from_info
        if @view && title_from_info = @view.info(:title)
          self.title = title_from_info
        end
      end

      def setup_form_field_names
        @view.object.find_significant_nodes(:form).each do |form_node|
          form_node.children.find_significant_nodes(:binding).each do |binding_node|
            binding_node.attributes[:name] ||= "#{form_node.label(:binding)}[#{binding_node.label(:binding)}]"
          end
        end
      end
    end
  end
end
