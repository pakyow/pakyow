# frozen_string_literal: true

require_relative "deep_dup"

module Pakyow
  module Support
    module ClassState
      using DeepDup

      def class_state(name, default: nil, inheritable: false, reader: true)
        ivar = :"@#{name}"

        @__class_state[ivar] = {
          default: default,
          inheritable: inheritable
        }

        instance_variable_set(ivar, default.deep_dup)

        if reader && !methods(false).include?(name)
          define_singleton_method(name) do
            instance_variable_get(ivar)
          end
        end
      end

      def self.extended(base)
        unless base.instance_variable_defined?(:@__class_state)
          base.instance_variable_set(:@__class_state, {})
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@__class_state, @__class_state.deep_dup)

        @__class_state.each do |ivar, options|
          if options[:inheritable]
            subclass.instance_variable_set(ivar, instance_variable_get(ivar).deep_dup)
          elsif @__class_state[ivar][:default]
            subclass.instance_variable_set(ivar, @__class_state[ivar][:default].deep_dup)
          else
            subclass.instance_variable_set(ivar, nil)
          end
        end

        super
      end
    end
  end
end
