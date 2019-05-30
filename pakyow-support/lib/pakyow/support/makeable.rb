# frozen_string_literal: true

require "pakyow/support/makeable/object_maker"
require "pakyow/support/makeable/object_name"

module Pakyow
  module Support
    # @api private
    module Makeable
      attr_reader :__object_name

      def make(object_name, within: nil, **kwargs, &block)
        unless object_name.is_a?(ObjectName) || object_name.nil?
          namespace = if within && within.respond_to?(:__object_name)
            within.__object_name.namespace
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

        if self.is_a?(Class)
          new_class = Class.new(self)
          eval_method = :class_eval
        elsif self.is_a?(Module)
          new_class = Module.new do
            def self.__object_name
              @__object_name
            end
          end

          eval_method = :module_eval
        end

        ObjectMaker.define_const_for_object_with_name(new_class, object_name)

        new_class.send(eval_method) do
          @__object_name = object_name

          kwargs.each do |arg, value|
            instance_variable_set(:"@#{arg}", value)
          end

          class_eval(&block) if block_given?
        end

        new_class
      end
    end
  end
end
