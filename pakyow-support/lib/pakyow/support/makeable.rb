# frozen_string_literal: true

require "pakyow/support/hookable"

require "pakyow/support/makeable/object_maker"
require "pakyow/support/object_name"

module Pakyow
  module Support
    module Makeable
      def self.extended(base)
        # Mixin the `make` event for objects that are hookable.
        #
        if base.ancestors.include?(Hookable)
          base.events :make
        end
      end

      attr_reader :object_name
      attr_accessor :source_name

      def make(object_name, within: nil, set_const: true, **kwargs, &block)
        @source_name = block&.source_location
        object_name = build_object_name(object_name, within: within)
        object = find_or_define_object(object_name, kwargs, set_const)

        local_eval_method = eval_method
        object.send(eval_method) do
          @object_name = object_name
          send(local_eval_method, &block) if block_given?
        end

        if object.ancestors.include?(Hookable)
          object.call_hooks(:after, :make)
        end

        object
      end

      private

      def build_object_name(object_name, within:)
        unless object_name.is_a?(ObjectName) || object_name.nil?
          namespace = if within && within.respond_to?(:object_name)
            within.object_name.namespace
          elsif within.is_a?(ObjectNamespace)
            within
          else
            ObjectNamespace.new
          end

          object_name_parts = object_name.to_s.gsub("-", "_").split("/").reject(&:empty?)
          class_name = object_name_parts.pop || :index

          object_name = Support::ObjectName.new(
            Support::ObjectNamespace.new(
              *(namespace.parts + object_name_parts)
            ), class_name
          )
        end

        object_name
      end

      def find_or_define_object(object_name, kwargs, set_const)
        if object_name && ::Object.const_defined?(object_name.constant, false)
          existing_object = ::Object.const_get(object_name.constant)

          if type_of_self?(existing_object)
            existing_object
          else
            define_object(kwargs)
          end
        else
          define_object(kwargs).tap do |defined_object|
            if set_const
              ObjectMaker.define_const_for_object_with_name(defined_object, object_name)
            end
          end
        end
      end

      def type_of_self?(object)
        object.ancestors.include?(ancestors[1])
      end

      def define_object(kwargs)
        object = case self
        when Class
          Class.new(self)
        when Module
          Module.new do
            def self.object_name
              @object_name
            end
          end
        end

        object.send(eval_method) do
          kwargs.each do |arg, value|
            instance_variable_set(:"@#{arg}", value)
          end
        end

        object
      end

      def eval_method
        case self
        when Class
          :class_exec
        when Module
          :module_exec
        end
      end
    end
  end
end
