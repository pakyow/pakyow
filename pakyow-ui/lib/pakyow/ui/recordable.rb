# frozen_string_literal: true

require "json"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/extension"
require "pakyow/support/inflector"

require "pakyow/data/sources/relational"

require "pakyow/presenter/binding_parts"
require "pakyow/presenter/versioned_view"
require "pakyow/presenter/presenter"

require "pakyow/ui/recordable/helpers/client_remapping"
require "pakyow/ui/recordable/attributes"

module Pakyow
  module UI
    module Recordable
      extend Support::Extension

      using Support::Refinements::Array::Ensurable

      attr_reader :calls

      def to_json(*)
        @calls.to_json
      end

      # @api private
      def cache_bindings!
        binding_nodes = if @view.object.is_a?(StringDoc::Node) && @view.object.significant?(:multipart_binding)
          [@view.object]
        else
          @view.object.find_significant_nodes(:binding)
        end

        @bindings = binding_nodes.flat_map { |node|
          [node.label(:binding), node.label(:binding_prop)]
        }.compact
      end

      private

      # FIXME: We currently viewify twice for present; once for transform, another for bind.
      # Let's create a `Viewified` object instead... then check to see if it's already happened.
      #
      def viewify(data)
        data = if data.is_a?(Data::Proxy)
          data.to_a
        elsif data.nil?
          []
        else
          Array.ensure(data)
        end

        data.map { |object|
          binder = wrap_data_in_binder(object)
          object = binder.object

          # Map object keys to the binding name.
          #
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

          # Add view-specific bindings that aren't in the object, but may exist in the binder.
          #
          @bindings.each do |binding_name|
            unless keys_and_binding_names.find { |_, k2| k2 == binding_name }
              keys_and_binding_names << [binding_name, binding_name]
            end
          end

          viewified = keys_and_binding_names.compact.uniq.each_with_object({}) { |(key, binding_name), values|
            value = binder.__value(key)

            if value.is_a?(String)
              value = ensure_html_safety(value)
            end

            if value.is_a?(Presenter::BindingParts)
              values[binding_name] = value.values(@view.find(binding_name))
            elsif !value.nil?
              values[binding_name] = value
            end
          }

          viewified
        }
      end

      def ensure_explicit_use(presenter)
        presenter.view.each_binding_prop(descend: false) do |binding_prop|
          binding_name = if binding_prop.significant?(:multipart_binding)
            binding_prop.label(:binding_prop)
          else
            binding_prop.label(:binding)
          end

          binding_prop_view = presenter.view.find(binding_name)

          if binding_prop_view.is_a?(Presenter::VersionedView)
            unless binding_prop_view.used?
              if binding_prop_view.version?(:default)
                presenter.instance_variable_get(:@calls).unshift([:find, [[binding_name]], [], [[:use, [:default], [], []]]])
              else
                presenter.instance_variable_get(:@calls).unshift([:find, [[binding_name]], [], [[:clean, [], [], []]]])
              end
            end
          end
        end

        if presenter.view.is_a?(Presenter::VersionedView)
          unless presenter.view.used?
            if presenter.view.version?(:default)
              presenter.instance_variable_get(:@calls).unshift([:use, [:default], [], []])
            else
              presenter.instance_variable_get(:@calls).unshift([:clean, [], [], []])
            end
          end
        end
      end

      apply_extension do
        include Helpers::ClientRemapping
      end

      class_methods do
        def from_presenter(presenter)
          allocate.tap { |instance|
            instance.instance_variable_set(:@calls, [])

            # Copy state from the presenter we're tracking.
            #
            presenter.instance_variables.each do |ivar|
              if ivar == :@__pipeline
                instance.instance_variable_set(ivar, presenter.class.__pipeline.callable(instance))
              else
                instance.instance_variable_set(ivar, presenter.instance_variable_get(ivar))
              end
            end

            instance.cache_bindings!
          }
        end
      end

      prepend_methods do
        def initialize(*)
          super

          @calls = []
          cache_bindings!
        end

        def presenter_for(view, type: Presenter::Presenter)
          if type == Presenter::Presenter
            self.class.from_presenter(super)
          else
            super
          end
        end

        %i(find transform use bind append prepend after before replace remove clear title= setup_endpoint wrap_endpoint_for_removal html=).each do |method_name|
          define_method method_name do |*args, &block|
            nested = []

            super(*args) { |nested_presenter, *nested_args|
              if block
                nested << nested_presenter
                block.call(nested_presenter, *nested_args).tap do
                  if method_name == :transform
                    ensure_explicit_use(nested_presenter)
                  end
                end
              end
            }.tap do |result|
              call_args = case method_name
              when :find
                # Because multiple bindings can be passed, we want to wrap them in
                # an array so that the client sees them as a single argument.
                #
                # We also want to send the channels.
                #
                if args.last.is_a?(Hash)
                  [args, args.pop]
                else
                  [args]
                end
              when :setup_endpoint
                # We don't want to send `node` down to the client.
                #
                args.tap do
                  args[0].delete(:node)
                end
              when :wrap_endpoint_for_removal
                # We don't want to send `node` down to the client.
                #
                args.tap do
                  args[0].delete(:node)
                end
              when :transform
                # Ignore the potential `yield_block` argument that's used internally.
                #
                [viewify(args[0])]
              when :bind
                # Modify the bound data to include only necessary values.
                #
                viewify(args)
              else
                args
              end

              subsequent = if (result.is_a?(Presenter::Presenter) && !result.equal?(self)) || result.is_a?(Attributes)
                result
              else
                []
              end

              @calls << [remap_for_client(method_name), call_args, nested, subsequent]
            end
          end
        end

        def attributes
          Attributes.from_attributes(super).tap do |subsequent|
            @calls << [:attributes, [], [], subsequent]
          end
        end
        alias attrs attributes
      end
    end
  end
end
