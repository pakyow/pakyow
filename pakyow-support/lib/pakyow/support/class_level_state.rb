# frozen_string_literal: true

module Pakyow
  module Support
    module ClassLevelState
      def class_level_state(name, value, inheritable: false)
        ivar = :"@#{name}"
        @class_level_state[ivar] = {
          inheritable: inheritable
        }

        instance_variable_set(ivar, value)

        define_singleton_method name do
          instance_variable_get(ivar)
        end
      end

      def self.extended(base)
        puts "extended #{base}"
        base.instance_variable_set(:@class_level_state, {})
      end

      def inherited(subclass)
        super

        subclass.instance_variable_set(:@class_level_state, @class_level_state.dup)

        @class_level_state.each do |ivar, options|
          next unless options[:inheritable]

          subclass.instance_variable_set(ivar, instance_variable_get(ivar).dup)
        end
      end
    end
  end
end
