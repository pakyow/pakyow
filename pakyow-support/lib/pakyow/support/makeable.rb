# frozen_string_literal: true

require "pakyow/support/makeable/class_maker"
require "pakyow/support/makeable/class_name"

module Pakyow
  module Support
    # @api private
    module Makeable
      # TODO: figure out where state as used and define it there; we don't care about it here
      attr_reader :__class_name, :state

      def make(class_name, within: nil, **kwargs, &block)
        unless class_name.is_a?(ClassName) || class_name.nil?
          namespace = if within && within.respond_to?(:__class_name)
            within.__class_name.namespace
          else
            ClassNamespace.new
          end

          class_name = ClassName.new(namespace, class_name)
        end

        new_class = Class.new(self)
        ClassMaker.define_const_for_class_with_name(new_class, class_name)

        new_class.class_eval do
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
