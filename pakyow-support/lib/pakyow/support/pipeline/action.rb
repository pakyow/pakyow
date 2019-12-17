# frozen_string_literal: true

module Pakyow
  module Support
    module Pipeline
      # @api private
      class Action
        attr_reader :target, :name, :options

        def initialize(target, *options, &block)
          @target, @options, @block = target, options, block

          if target.is_a?(Symbol)
            @name = target
          end
        end

        def finalize(context = nil)
          if @block
            if context
              if @block.arity == 0
                Proc.new do
                  context.instance_exec(&@block)
                end
              else
                Proc.new do |object|
                  context.instance_exec(object, &@block)
                end
              end
            else
              @block
            end
          elsif @target.is_a?(Symbol) && context.respond_to?(@target, true) && (options[0].nil? || !options[0].instance_methods(false).include?(:call))
            if context
              context.method(@target)
            else
              raise "finalizing pipeline action #{@target} requires context"
            end
          else
            target, target_options = if @target.is_a?(Symbol)
              [@options[0], @options[1..-1]]
            else
              [@target, @options]
            end

            instance = if target.is_a?(Class)
              target.new(*target_options)
            else
              target
            end

            instance.method(:call)
          end
        end
      end
    end
  end
end
