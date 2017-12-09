# frozen_string_literal: true

require "forwardable"

require "pakyow/presenter/attributes/boolean"
require "pakyow/presenter/attributes/hash"
require "pakyow/presenter/attributes/set"
require "pakyow/presenter/attributes/string"

module Pakyow
  module Presenter
    class ViewAttributes
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
      end

      # Object for hash attributes
      ATTRIBUTE_TYPE_HASH    = Attributes::Hash
      # Object for set attributes
      ATTRIBUTE_TYPE_SET     = Attributes::Set
      # Object for boolean attributes
      ATTRIBUTE_TYPE_BOOLEAN = Attributes::Boolean
      # Default attribute object
      ATTRIBUTE_TYPE_DEFAULT = Attributes::String

      # Maps non-default attributes to their type
      ATTRIBUTE_TYPES = {
        class:    ATTRIBUTE_TYPE_SET,
        style:    ATTRIBUTE_TYPE_HASH,
        selected: ATTRIBUTE_TYPE_BOOLEAN,
        checked:  ATTRIBUTE_TYPE_BOOLEAN,
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
          attributes[name] = ViewAttributes.typed_value_for_attribute_with_name(value, name)
        end

        @attributes = attributes
      end

      def [](attribute)
        # Note that if +attribute+ isn't present in the view, the return value
        # will be nil. This could potentially cause a regression in real-world
        # cases. Consider if we started with this view:
        #
        #   <div class="foo"></div>
        #
        # Backend code would likey be written as follows:
        #
        #   view.attrs[:class] << "bar"
        #
        # The thinking is you don't want to modify values in the view. However,
        # if the view is later refactored to not have a class attribute the
        # backend code will error out.
        #
        # Generally we care about preventing these cases. However, in the case
        # of attributes, these are acceptable. The case I laid out above should
        # be considered bad practice but allowed by the framework. Versioned
        # views should be used instead, which lets the backend choose which
        # one to use but gives the frontend full ownership over class names.
        # This removes unnecessary coordination.
        #
        # We could probably support this in a non-breaking way from the backend,
        # but the complexity it would add makes it not worth it. Some things
        # can and should be prevented in code, but this seems like policy.
        #
        # Same ideas apply to non-class attributes as well.

        attribute = attribute.to_sym

        if self.class.type_of_attribute(attribute) == ATTRIBUTE_TYPE_BOOLEAN
          @attributes.key?(attribute)
        else
          @attributes[attribute.to_sym]
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
    end
  end
end
