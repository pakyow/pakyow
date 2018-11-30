# frozen_string_literal: true

require "forwardable"

require "pakyow/presenter/attributes/boolean"
require "pakyow/presenter/attributes/hash"
require "pakyow/presenter/attributes/set"
require "pakyow/presenter/attributes/string"

module Pakyow
  module Presenter
    class Attributes
      class << self
        def typed_value_for_attribute_with_name(value, name)
          type = type_of_attribute(name.to_sym)

          if value.is_a?(type)
            value
          else
            type.parse(value)
          end
        end

        def type_of_attribute(attribute)
          ATTRIBUTE_TYPES[attribute.to_sym] || ATTRIBUTE_TYPE_DEFAULT
        end

        def default_value_for_attribute(attribute)
          type = type_of_attribute(attribute.to_sym)
          if type == ATTRIBUTE_TYPE_SET
            ::Set.new
          elsif type == ATTRIBUTE_TYPE_HASH
            ::Hash.new
          elsif type == ATTRIBUTE_TYPE_BOOLEAN
            false
          else
            ::String.new
          end
        end
      end

      # Object for hash attributes
      ATTRIBUTE_TYPE_HASH = Attributes::Hash
      # Object for set attributes
      ATTRIBUTE_TYPE_SET = Attributes::Set
      # Object for boolean attributes
      ATTRIBUTE_TYPE_BOOLEAN = Attributes::Boolean
      # Default attribute object
      ATTRIBUTE_TYPE_DEFAULT = Attributes::String

      # Maps non-default attributes to their type
      ATTRIBUTE_TYPES = {
        class: ATTRIBUTE_TYPE_SET,
        style: ATTRIBUTE_TYPE_HASH,
        selected: ATTRIBUTE_TYPE_BOOLEAN,
        checked: ATTRIBUTE_TYPE_BOOLEAN,
        disabled: ATTRIBUTE_TYPE_BOOLEAN,
        readonly: ATTRIBUTE_TYPE_BOOLEAN,
        multiple: ATTRIBUTE_TYPE_BOOLEAN,
      }.freeze

      extend Forwardable

      # @!method keys
      #   Returns keys from {@attributes}.
      #
      # @!method []
      #   Returns value of key from {@attributes}.
      #
      # @!method []=
      #   Returns sets value for key on {@attributes}.
      #
      # @!method delete
      #   Deletes key by name from {@attributes}.
      #
      def_delegators :@attributes, :keys, :delete, :each

      # Wraps a hash of view attributes
      #
      # @param attributes [Hash]
      #
      def initialize(attributes)
        attributes.each do |name, value|
          attributes[name] = Attributes.typed_value_for_attribute_with_name(value, name)
        end

        @attributes = attributes
      end

      def [](attribute)
        attribute = attribute.to_sym
        attribute_type = self.class.type_of_attribute(attribute)

        if attribute_type == ATTRIBUTE_TYPE_BOOLEAN
          @attributes.key?(attribute)
        else
          @attributes[attribute] ||= attribute_type.new(self.class.default_value_for_attribute(attribute))
        end
      end

      def []=(attribute, value)
        attribute = attribute.to_sym

        if value.nil?
          @attributes.delete(attribute)
        elsif self.class.type_of_attribute(attribute) == ATTRIBUTE_TYPE_BOOLEAN
          if value
            @attributes[attribute] = self.class.typed_value_for_attribute_with_name(attribute, attribute)
          else
            @attributes.delete(attribute)
          end
        else
          @attributes[attribute] = self.class.typed_value_for_attribute_with_name(value, attribute)
        end
      end

      def has?(attribute)
        @attributes.key?(attribute.to_sym)
      end
    end
  end
end
