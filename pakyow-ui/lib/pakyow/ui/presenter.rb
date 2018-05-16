# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/safe_string"

module Pakyow
  module UI
    # Tracks calls to a presenter, then serializes them.
    #
    class Presenter
      using Support::Refinements::Array::Ensurable

      def initialize(presenter)
        @presenter = presenter

        @bindings = if presenter.respond_to?(:view)
          (presenter.view.binding_scopes + presenter.view.binding_props).map { |view|
            view.label(:binding)
          }
        else
          []
        end

        @calls = []
      end

      UNSUPPORTED = %i(view layout page partials find_all forms action= method= options_for grouped_options_for)
      def method_missing(method_name, *args)
        if @presenter.respond_to?(method_name)
          calls_for_each = []

          wrap(@presenter.public_send(method_name, *args) { |nested_presenter, *nested_args|
            if block_given?
              wrapped_nested_presenter = wrap(nested_presenter)
              calls_for_each << wrapped_nested_presenter
              yield wrapped_nested_presenter, *nested_args
            end
          }).tap { |wrapped|
            if method_name == :present
              data = if args[0].is_a?(Data::Source)
                args[0].to_a
              else
                Array.ensure(args[0])
              end

              viewify!(data)
            end

            if method_name == :find
              # Because multiple bindings can be passed, we want to wrap them in
              # an array so that the client sees them as a single argument.
              args = [args]
            end

            if UNSUPPORTED.include?(method_name)
              Pakyow.logger.warn "`#{method_name}' is unsupported in pakyow/ui"
            else
              @calls << [method_name, args, calls_for_each, wrapped]
            end
          }
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @presenter.respond_to?(method_name) || super
      end

      def to_json(*)
        @calls.to_json
      end

      def block
        @presenter.class.block
      end

      private

      def wrap(result)
        self.class.new(result)
      end

      include Support::SafeStringHelpers

      # Converts keys in each presented object to match the binding names in the
      # view, preventing us from needing an inflector on the client side.
      #
      # For example, `data.posts.include(:comments)` includes data with the `comments`
      # key which would not map to the singular `comment` binding in the view. Running
      # this case through `rekey_data!` would convert `comments` to `comment`.
      #
      # Also makes sure values are html safe, mixes in values from binders, and
      # rejects any values that the view won't end up needing.
      #
      def viewify!(data)
        data.map! { |object|
          binder = @presenter.wrap_data_in_binder(object)

          keys_and_binding_names = object.to_h.keys.map { |key|
            if key == :id || @bindings.include?(key)
              binding_name = key
            else
              plural_binding_name = Support.inflector.pluralize(key.to_s).to_sym
              singular_binding_name = Support.inflector.singularize(key.to_s).to_sym

              if @bindings.include?(plural_binding_name)
                binding_name = plural_binding_name
              elsif @bindings.include?(singular_binding_name)
                binding_name = singular_binding_name
              else
                next
              end
            end

            [key, binding_name]
          }

          # add view-specific bindings that aren't in the object, but may exist in the binder
          @bindings.each do |binding_name|
            unless keys_and_binding_names.find { |_, k2| k2 == binding_name }
              keys_and_binding_names << [binding_name, binding_name]
            end
          end

          viewified = keys_and_binding_names.compact.uniq.each_with_object({}) { |(key, binding_name), values|
            value = binder.value(key)
            value = ensure_html_safety(value) if value.is_a?(String)
            values[binding_name] = value unless value.nil?
          }

          object.class.new(viewified)
        }
      end
    end
  end
end
