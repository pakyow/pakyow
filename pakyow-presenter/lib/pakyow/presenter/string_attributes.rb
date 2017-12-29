# frozen_string_literal: true

require "forwardable"

require "pakyow/support/deep_dup"

module Pakyow
  module Presenter
    # String-based XML attributes.
    #
    # @see StringDoc
    #
    class StringAttributes
      OPENING = '="'
      CLOSING = '"'
      SPACING = " "

      using Support::DeepDup

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
      def_delegators :@attributes_hash, :keys, :[], :[]=, :delete, :each, :key?

      def initialize(attributes_hash = {})
        @attributes_hash = attributes_hash
      end

      def to_s
        string = @attributes_hash.compact.map { |name, value|
          name.to_s + OPENING + value.to_s + CLOSING
        }.join(SPACING)

        if string.empty?
          string
        else
          SPACING + string
        end
      end

      def ==(other)
        other.is_a?(StringAttributes) && @attributes_hash == other.attributes_hash
      end

      # @api private
      attr_reader :attributes_hash

      # @api private
      def initialize_copy(_)
        @attributes_hash = @attributes_hash.deep_dup
      end
    end
  end
end
