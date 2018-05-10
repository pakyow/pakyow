# frozen_string_literal: true

module Pakyow
  module UI
    # Tracks calls to a presenter, then serializes them.
    #
    class Presenter
      def initialize(presenter)
        @presenter = presenter
        @calls = []
      end

      IGNORE = %i()
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
              rekey_data!(args[0].to_a)
            end

            @calls << [method_name, args, calls_for_each, wrapped]
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

      # Converts keys in each presented object to match the binding names in the
      # view, preventing us from needing an inflector on the client side.
      #
      # For example, `data.posts.include(:comments)` includes data with the `comments`
      # key which would not map to the singular `comment` binding in the view. Running
      # this case through `rekey_data!` would convert `comments` to `comment`.
      #
      def rekey_data!(data)
        @presenter.view.binding_scopes.each do |scope|
          binding_name = scope.label(:binding)
          singular_binding_name = Support.inflector.singularize(binding_name.to_s).to_sym
          plural_binding_name = Support.inflector.pluralize(binding_name.to_s).to_sym

          data.map! { |object|
            if object.key?(binding_name)
              object
            else
              object.class.new(Hash[object.values.map { |key, value|
                if key == plural_binding_name
                  [singular_binding_name, value]
                elsif key == singular_binding_name
                  [plural_binding_name, value]
                else
                  [key, value]
                end
              }])
            end
          }
        end
      end
    end
  end
end
