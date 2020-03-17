# frozen_string_literal: true

require "securerandom"

require "pakyow/support/inspectable"

module Pakyow
  module Support
    module Pipeline
      # @api private
      class Action
        include Inspectable
        inspectable :name

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

        def call(context, *args, &next_action)
          callable.call(context, *args, &next_action)
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
          case block.arity
          when 0
            Proc.new do |context, *|
              context.instance_eval(&block)
            end
          else
            Proc.new do |context, *args|
              context.instance_exec(*args, &block)
            end
          end
        end

        private def build_method(method)
          case method.arity
          when 0
            Proc.new do |context, *, &next_action|
              method.bind(context).call(&next_action)
            end
          else
            Proc.new do |context, *args, &next_action|
              method.bind(context).call(*args, &next_action)
            end
          end
        end

        private def build_object(object)
          case object.method(:call).arity
          when 0
            Proc.new do |context, *, &next_action|
              object.call(&next_action)
            end
          else
            Proc.new do |context, *args, &next_action|
              object.call(*args, &next_action)
            end
          end
        end
      end
    end
  end
end
