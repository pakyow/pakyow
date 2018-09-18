# frozen_string_literal: true

require "pakyow/support/makeable/class_maker"
require "pakyow/support/makeable/class_name"

module Pakyow
  module Support
    # @api private
    module Makeable
      attr_reader :__class_name

      def make(class_name, within: nil, **kwargs, &block)
        unless class_name.is_a?(ClassName) || class_name.nil?
          namespace = if within && within.respond_to?(:__class_name)
            within.__class_name.namespace
          elsif within.is_a?(ClassNamespace)
            within
          else
            ClassNamespace.new
          end

          class_name = ClassName.new(namespace, class_name)
        end

        if self.is_a?(Class)
          new_class = Class.new(self)
          eval_method = :class_eval
        elsif self.is_a?(Module)
          new_class = Module.new do
            def self.__class_name
              @__class_name
            end
          end

          eval_method = :module_eval
        end

        ClassMaker.define_const_for_class_with_name(new_class, class_name)

        new_class.send(eval_method) do
          @__class_name = class_name

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
