module Pakyow
  module Support
    # Creates a Hash-like object can access stored data with symbol or
    #   string keys.
    #
    # The original hash is converted to frozen string keys, which means
    #   that a hash that originally contains a symbol and string key
    #   with the same frozen string value will conflict. It is not
    #   guaranteed which value will be saved.
    #
    # IndifferntHash instances have the same api as Hash, but any method
    #   that would return a Hash, will return an IndifferentHash.
    #
    # NOTE: Please lookup Ruby's docuementation for Hash to learn what
    #   methods are available.
    #
    # @example
    #   { test: 'test1', 'test' => 'test2' } => { test: 'test2' }
    #
    class IndifferentHash < SimpleDelegator
      class << self
        def deep(hash)
          pairs = hash.to_h.each_pair.map do |key, value|
            case value
            when Hash
              value = deep(value)
            when Array
              value = value.map { |value_item| deep(value_item) }
            end
            [key, value]
          end

          self.new(Hash[pairs])
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
              keys = keys.map do |key|
                convert_key(key)
              end
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

      def initialize(hash)
        self.internal_hash = hash
      end

      indifferent_key_method :[], :[]=, :default, :delete, :fetch, :has_key?, :key?, :include?, :member?, :store
      indifferent_multi_key_method :fetch_values, :values_at, :dig
      indifferentize_return_method :merge, :invert, :compact, :reject, :select, :transform_values, :deep_merge
      indifferentize_update_method :merge!, :update, :replace, :clear, :keep_if, :delete_if, :compact!, :reject!, :select!, :deep_merge!
      indifferentize_argument_method :>, :>=, :<=>, :<, :<=, :==

      def internal_hash
        __getobj__
      end

      def to_h
        self
      end
      alias to_hash to_h

      private

      def internal_hash=(other)
        __setobj__(stringify_keys(other))
      end

      def stringify_keys(hash)
        return hash unless hash.respond_to?(:to_h)

        hash.to_h.each_with_object({}) do |(key, value), converted|
          key = convert_key(key)
          converted[key] = value
        end
      end

      def convert_key(key)
        case key
        when Symbol, String
          key.to_s.freeze
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
