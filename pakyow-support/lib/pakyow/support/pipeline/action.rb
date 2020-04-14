# frozen_string_literal: true

require "securerandom"

require_relative "../core_refinements/method/introspection"
require_relative "../core_refinements/unbound_method/introspection"
require_relative "../core_refinements/proc/introspection"

require_relative "../inspectable"

module Pakyow
  module Support
    module Pipeline
      # @api private
      class Action
        include Inspectable
        inspectable :name

        using Refinements::Method::Introspection
        using Refinements::UnboundMethod::Introspection
        using Refinements::Proc::Introspection

        attr_reader :target, :name, :options

        def initialize(def_context, target, *options, &block)
          @target, @options, @block = target, options, block

          if target.is_a?(Symbol)
            @name = target
          end

          # This is a temporary context needed for method lookups. It's reset at the end of `build`.
          #
          @def_context = def_context
        end

        def call(context, *args, **kwargs, &next_action)
          callable.call(context, *args, **kwargs, &next_action)
        end

        def freeze(*)
          # Finalize the action before it's frozen.
          #
          callable

          super
        end

        # @api private
        def reset(def_context)
          @def_context = def_context
          @callable = nil
          self
        end

        private def callable
          @callable ||= build
        end

        private def build
          callable = if @block
            build_block(@target, @block)
          else
            case @target
            when Symbol
              if @options[0]
                case @options[0]
                when Class
                  build_object(options[0].new(*options[1..-1]))
                when Proc
                  build_block(@target, @options[0])
                else
                  build_object(options[0])
                end
              else
                build_method(@def_context.instance_method(@target))
              end
            when Class
              build_object(@target.new(*@options))
            when Proc
              build_block(nil, @target)
            else
              build_object(@target)
            end
          end

          @def_context = nil

          callable
        end

        private def build_block(name, block)
          wrap_callable(
            block,
            block_empty: -> (context, &next_action) {
              context.instance_eval(&block)
            },
            block_args: -> (context, *args, &next_action) {
              context.instance_exec(*args, &block)
            },
            block_kwargs: -> (context, *args, **kwargs, &next_action) {
              context.instance_exec(*args, **kwargs, &block)
            }
          )
        end

        private def build_method(method)
          wrap_callable(
            method,
            block_empty: -> (context, &next_action) {
              method.bind(context).call(&next_action)
            },
            block_args: -> (context, *args, &next_action) {
              method.bind(context).call(*args, &next_action)
            },
            block_kwargs: -> (context, *args, **kwargs, &next_action) {
              method.bind(context).call(*args, **kwargs, &next_action)
            }
          )
        end

        private def build_object(object)
          wrap_callable(
            object.method(:call),
            block_empty: -> (_, &next_action) {
              object.call(&next_action)
            },
            block_args: -> (_, *args, &next_action) {
              object.call(*args, &next_action)
            },
            block_kwargs: -> (_, *args, **kwargs, &next_action) {
              object.call(*args, **kwargs, &next_action)
            }
          )
        end

        private def wrap_callable(callable, block_empty:, block_args:, block_kwargs:)
          if callable.keyword_arguments?
            if callable.argument_list?
              if callable.is_a?(Proc) || callable.arity > 1 || callable.arity < -1
                Proc.new do |context, *args, **kwargs, &next_action|
                  block_kwargs.call(context, *args, **kwargs, &next_action)
                end
              else
                Proc.new do |context, *, **kwargs, &next_action|
                  block_kwargs.call(context, **kwargs, &next_action)
                end
              end
            else
              Proc.new do |context, **kwargs, &next_action|
                block_kwargs.call(context, **kwargs, &next_action)
              end
            end
          else
            if callable.argument_list?
              if callable.is_a?(Proc) || callable.arity > 1 || callable.arity < -1
                Proc.new do |context, *args, **, &next_action|
                  block_args.call(context, *args, &next_action)
                end
              else
                Proc.new do |context, state, *, **, &next_action|
                  block_args.call(context, state, &next_action)
                end
              end
            else
              Proc.new do |context, *, **, &next_action|
                block_empty.call(context, &next_action)
              end
            end
          end
        end
      end
    end
  end
end
