# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module ClassLevelState
      using DeepDup

      def class_level_state(name, default: nil, inheritable: false, getter: true)
        ivar = :"@#{name}"
        @class_level_state[ivar] = {
          inheritable: inheritable
        }

        instance_variable_set(ivar, default)

        if getter
          define_singleton_method name do
            instance_variable_get(ivar)
          end
        end
      end

      def self.extended(base)
        unless base.instance_variable_defined?(:@class_level_state)
          base.instance_variable_set(:@class_level_state, {})
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set(:@class_level_state, @class_level_state.deep_dup)

        @class_level_state.each do |ivar, options|
          next unless options[:inheritable]

          subclass.instance_variable_set(ivar, instance_variable_get(ivar).deep_dup)
        end

        super
      end
    end
  end
end
