# frozen_string_literal: true

require "json"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/extension"
require "pakyow/support/inflector"
require "pakyow/support/safe_string"
require "pakyow/support/system"

require "pakyow/data/sources/relational"

require "pakyow/presenter/binding_parts"
require "pakyow/presenter/versioned_view"
require "pakyow/presenter/presenter"

require_relative "recordable/helpers/client_remapping"
require_relative "recordable/attributes"

module Pakyow
  module UI
    # @api private
    module Recordable
      extend Support::Extension

      include Support::SafeStringHelpers

      using Support::Refinements::Array::Ensurable

      # @api private
      attr_reader :calls

      def to_json(*)
        optimized.to_json
      end

      def to_a
        @calls
      end

      # @api private
      def cache_bindings!
        binding_nodes = if (view.object.is_a?(StringDoc::Node) || view.object.is_a?(StringDoc::MetaNode)) && view.object.significant?(:multipart_binding)
          [view.object]
        else
          view.object.find_significant_nodes(:binding)
        end

        @bindings = binding_nodes.flat_map { |node|
          [node.label(:binding), node.label(:binding_prop)]
        }.compact
      end

      private def optimized
        calls = []

        # Combine finds when looking for the same nodes.
        #
        @calls.each do |call|
          if call[0] == :find && (matching_call = calls.find { |c| c[0] == :find && c[1] == call[1] && c[2] == call[2] })
            matching_call[3].to_a.concat(call[3].to_a)
          else
            calls << call
          end
        end

        # Prioritize the calls so they are applied correctly on the client.
        #
        calls.sort! do |a, b|
          call_priority(a, calls) <=> call_priority(b, calls)
        end

        calls
      end

      PRIORITY_CALLS = %i[transform use].freeze

      private def call_priority(call, calls)
        if PRIORITY_CALLS.include?(call[0])
          # Set priority calls to a priority of -1000, which is highest priority.
          #
          -1000
        elsif call[0] == :find
          # Make priority of finds an inverse of specificity (e.g. [:post] > [:post, :title]).
          #
          -1000 + call[1][0].count
        else
          # Or just keep the same order we have now.
          #
          calls.index(call)
        end
      end

      # FIXME: We currently viewify twice for present; once for transform, another for bind.
      # Let's create a `Viewified` object instead... then check to see if it's already happened.
      #
      private def viewify(data)
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
            key = key.to_sym
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

      apply_extension do
        include Helpers::ClientRemapping
      end

      def self.find_through(binding_path, binding_info, options, context, calls)
        if binding_path.any?
          binding_path_part = binding_path.shift
          current_options = options.dup

          if (id = binding_info[binding_path_part.to_s.split(":", 2)[0].to_sym])
            # Tie the transformations to a node of a specific id, unless we're transforming the entire set.
            #
            unless calls.any? { |call| call[0] == :transform }
              current_options["id"] = id
            end
          end

          subsequent = []

          args = [[binding_path_part]]
          unless current_options.empty?
            args << current_options
          end

          context << [
            :find,
            args, [], subsequent
          ]

          find_through(binding_path, binding_info, options, subsequent, calls)
        else
          context.concat(calls)
        end
      end

      class_methods do
        def render_proc(view, render, &block)
          super(view, render) do |_, context|
            instance_exec(&block)

            if render[:node]
              # The super proc creates a new presenter instance per render, but we want each to use the
              # same starting point for calls since they all apply to the same node.
              #
              context.calls.concat(calls)
            elsif calls.any?
              # Explicitly find the node to apply the transformation to the correct node. While
              # we're at it, append any transformations caused by the `instance_exec` above.
              #
              Recordable.find_through(
                render[:binding_path].dup, object.label(:binding_info).to_h, {}, context.calls, calls
              )
            end
          end
        end

        def from_presenter(presenter)
          allocate.tap do |instance|
            # Copy state from the presenter we're tracking.
            #
            presenter.instance_variables.each do |ivar|
              instance.instance_variable_set(ivar, presenter.instance_variable_get(ivar))
            end

            instance.cache_bindings!
          end
        end
      end

      prepend_methods do
        if Support::System.ruby_version < "2.7.0"
          def initialize(*)
            super
            __common_ui_recordable_initialize
          end
        else
          def initialize(*, **)
            super
            __common_ui_recordable_initialize
          end
        end

        private def __common_ui_recordable_initialize
          @calls = []
          cache_bindings!
        end

        def presenter_for(view, type: view&.label(:presenter_type))
          presenter = super

          if presenter.is_a?(Delegator)
            presenter.__setobj__(self.class.from_presenter(presenter.__getobj__))
          else
            presenter = self.class.from_presenter(presenter)
          end

          presenter
        end

        %i[
          find transform use bind append prepend after before replace remove clear title= html=
          endpoint endpoint_action component
        ].each do |method_name|
          define_method method_name do |*args, &block|
            nested = []

            super(*args) { |nested_presenter, *nested_args|
              if block
                nested << nested_presenter
                block.call(nested_presenter, *nested_args)
              end
            }.tap do |result|
              call_args = case method_name
              when :find
                # Because multiple bindings can be passed, we want to wrap them in
                # an array so that the client sees them as a single argument.
                #
                [args]
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

              subsequent = if (result.is_a?(Presenter::Presenter) && !result.equal?(self)) || (result.is_a?(Delegator) && !result.__getobj__.equal?(self)) || result.is_a?(Attributes)
                result
              else
                []
              end

              calls << [remap_for_client(method_name), call_args, nested, subsequent]
            end
          end
        end

        def attributes
          Attributes.from_attributes(super).tap do |subsequent|
            calls << [:attributes, [], [], subsequent]
          end
        end
        alias_method :attrs, :attributes
      end
    end
  end
end
