# frozen_string_literal: true

require "delegate"

require_relative "thread_localizer"

module Pakyow
  module Support
    # Refines Object, Array, and Hash with support for deep_dup.
    #
    # @example
    #   using DeepDup
    #   state = { "foo" => ["bar"] }
    #   duped = state.deep_dup
    #
    #   state.keys[0] === duped.keys[0]
    #   => false
    #
    #   state.values[0][0] === duped.values[0][0]
    #   => false
    #
    module DeepDup
      # @api private
      def self.prevent_dup_recursion(object)
        duped_objects[object.object_id] = true

        yield
      ensure
        duped_objects.delete(object.object_id)
      end

      # @api private
      def self.duping?(object)
        duped_objects[object.object_id]
      end

      # @api private
      def self.duped_objects
        ThreadLocalizer.thread_localized_store[:__pw_duped_objects] ||= {}
      end

      # Objects that can't be copied.
      UNDUPABLE = [Symbol, Integer, NilClass, TrueClass, FalseClass, Class, Module].freeze

      [Object, Delegator].each do |klass|
        refine klass do
          # Returns a copy of the object.
          #
          def deep_dup
            unless DeepDup.duping?(self)
              DeepDup.prevent_dup_recursion(self) do
                if UNDUPABLE.include?(self.class)
                  self
                else
                  dup
                end
              end
            end
          end
        end
      end

      refine Array do
        # Returns a deep copy of the array.
        #
        def deep_dup
          unless DeepDup.duping?(self)
            DeepDup.prevent_dup_recursion(self) do
              map(&:deep_dup)
            end
          end
        end
      end

      refine Hash do
        # Returns a deep copy of the hash.
        #
        def deep_dup
          unless DeepDup.duping?(self)
            DeepDup.prevent_dup_recursion(self) do
              hash = dup
              each_pair do |key, value|
                hash.delete(key)
                hash[key.deep_dup] = value.deep_dup
              end

              hash
            end
          end
        end
      end
    end
  end
end
