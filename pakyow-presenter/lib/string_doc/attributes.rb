# frozen_string_literal: true

require "forwardable"

require "pakyow/support/deep_dup"

class StringDoc
  # String-based XML attributes.
  #
  class Attributes
    OPENING = '="'
    CLOSING = '"'
    SPACING = " "

    include Pakyow::Support::SafeStringHelpers

    using Pakyow::Support::DeepDup

    extend Forwardable

    # @!method keys
    #   Returns the attribute keys.
    #
    # @!method key?
    #   Returns true if value is a key.
    #
    # @!method []
    #   Looks up a value for an attribute.
    #
    # @!method []=
    #   Sets a value for an attribute.
    #
    # @!method delete
    #   Removes an attribute by name.
    #
    # @!method each
    #   Yields each attribute.
    #
    def_delegators :@attributes_hash, :keys, :each

    def initialize(attributes_hash = {})
      @attributes_hash = Hash[attributes_hash.map { |key, value|
        [key.to_s, value]
      }]
    end

    def []=(key, value)
      @attributes_hash[key.to_s] = value
    end

    def [](key)
      @attributes_hash[key.to_s]
    end

    def delete(key)
      @attributes_hash.delete(key.to_s)
    end

    def key?(key)
      @attributes_hash.key?(key.to_s)
    end

    def to_s
      string = @attributes_hash.compact.map { |name, value|
        name + OPENING + value.to_s + CLOSING
      }.join(SPACING)

      if string.empty?
        string
      else
        SPACING + string
      end
    end

    def each_string
      if @attributes_hash.empty?
        yield ""
      else
        @attributes_hash.each do |name, value|
          yield SPACING
          yield name
          yield OPENING
          yield value.to_s
          yield CLOSING
        end
      end
    end

    def ==(other)
      other.is_a?(Attributes) && @attributes_hash == other.attributes_hash
    end

    # @api private
    attr_reader :attributes_hash

    # @api private
    def initialize_copy(_)
      @attributes_hash = @attributes_hash.deep_dup
    end
  end
end
