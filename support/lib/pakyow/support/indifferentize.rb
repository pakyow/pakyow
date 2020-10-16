# frozen_string_literal: true

require "delegate"

module Pakyow
  module Support
    # Creates a Hash-like object can access stored data with symbol or
    #   string keys.
    #
    # The original hash is converted to symbol keys, which means
    #   that a hash that originally contains a symbol and string key
    #   with the same symbold value will conflict. It is not guaranteed
    #   which value will be saved.
    #
    # IndifferentHash instances have the same api as Hash, but any method
    #   that would return a Hash, will return an IndifferentHash (with
    #   the exception of to_h/to_hash).
    #
    # NOTE: Please lookup Ruby's documentation for Hash to learn what
    #   methods are available.
    #
    # @example
    #   { test: "test1", "test" => "test2" } => { test: "test2" }
    #
    class IndifferentHash < SimpleDelegator
      class << self
        def deep(object)
          hash = object.to_h
          unless hash.empty?
            hash = hash.each_with_object({}) { |(key, value), new_hash|
              new_hash[key] = case value
              when Hash
                deep(value)
              when Array
                value.map { |value_item|
                  case value_item
                  when Hash
                    deep(value_item)
                  else
                    value_item
                  end
                }
              else
                value
              end
            }
          end

          new(hash)
        end

        private

        def indifferent_key_method(*methods)
          methods.each do |name|
            define_method(name) do |key = nil, *args, &block|
              key = convert_key(key)
              internal_hash.public_send(name, key, *args, &block)
            end
          end
        end

        def indifferent_multi_key_method(*methods)
          methods.each do |name|
            define_method(name) do |*keys, &block|
              keys = keys.map { |key|
                convert_key(key)
              }
              internal_hash.public_send(name, *keys, &block)
            end
          end
        end

        def indifferentize_return_method(*methods)
          methods.each do |name|
            define_method(name) do |*args, &block|
              hash = internal_hash.public_send(name, *args, &block)
              self.class.new(hash) if hash
            end
          end
        end

        def indifferentize_update_method(*methods)
          methods.each do |name|
            define_method(name) do |*args, &block|
              args = args.map { |arg| stringify_keys(arg) }
              hash = internal_hash.public_send(name, *args, &block)
              self if hash
            end
          end
        end

        def indifferentize_argument_method(*methods)
          methods.each do |name|
            define_method(name) do |*args, &block|
              args = args.map { |arg| stringify_keys(arg) }
              internal_hash.public_send(name, *args, &block)
            end
          end
        end
      end

      def initialize(hash = {})
        self.internal_hash = hash
      end

      indifferent_key_method :[], :[]=, :default, :delete, :fetch, :has_key?, :key?, :include?, :member?, :store
      indifferent_multi_key_method :fetch_values, :values_at, :dig
      indifferentize_return_method :merge, :invert, :compact, :reject, :select, :transform_values
      indifferentize_update_method :merge!, :update, :replace, :clear, :keep_if, :delete_if, :compact!, :reject!, :select!
      indifferentize_argument_method :>, :>=, :<=>, :<, :<=, :==

      # @api private
      def internal_hash
        __getobj__
      end

      def to_h
        internal_hash.each_with_object({}) { |(key, value), new_hash|
          key = case key
          when String
            key.to_sym
          else
            key
          end

          value = case value
          when IndifferentHash
            value.to_h
          else
            value
          end

          new_hash[key] = value
        }
      end
      alias_method :to_hash, :to_h

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end

      private

      def internal_hash=(other)
        __setobj__(stringify_keys(other))
      end

      def stringify_keys(object)
        return object unless object.respond_to?(:to_h)

        converted = {}
        object.to_h.each do |key, value|
          converted[convert_key(key)] = value
        end

        converted
      end

      def convert_key(key)
        case key
        when Symbol
          key.to_s
        else
          key
        end
      end
    end

    module Indifferentize
      refine Hash do
        def indifferentize
          Pakyow::Support::IndifferentHash.new(self)
        end

        def deep_indifferentize
          Pakyow::Support::IndifferentHash.deep(self)
        end
      end
    end
  end
end
