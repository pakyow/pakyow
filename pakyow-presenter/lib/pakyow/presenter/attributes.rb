require "forwardable"

module Pakyow
  module Presenter
    # @api private
    class StringAttribute
      # Typecasts +value+ to a string and returns. There's really no need to create
      # a +Pakyow::StringAttribute+ instance here since it would behave as a +String+.
      #
      def self.parse(value)
        value.to_s
      end
    end

    # @api private
    class BooleanAttribute
      # Simply returns +value+. This is here mainly for API consistency. Ultimately
      # though we want to deal with the truthiness of the underlying +value+.
      #
      def self.parse(value)
        value
      end
    end

    # @api public
    class SetAttribute < Set
      # @api private
      VALUE_SEPARATOR = " ".freeze

      # @api private
      def self.parse(value)
        SetAttribute[value.split(VALUE_SEPARATOR)]
      end

      # @api private
      def to_s
        join(VALUE_SEPARATOR)
      end
    end

    # @api public
    class HashAttribute < Hash
      # @api private
      VALUE_SEPARATOR = ":".freeze
      # @api private
      PAIR_SEPARATOR  = ";".freeze

      # @api private
      def self.parse(value)
        HashAttribute[value.split(PAIR_SEPARATOR).each_with_object({}) { |style, attributes|
          key, value = style.split(VALUE_SEPARATOR)
          attributes[key.strip.to_sym] = value.strip
        }]
      end

      # @api private
      def to_s
        to_a.map { |value| value.join(VALUE_SEPARATOR) }.join(PAIR_SEPARATOR)
      end
    end

    class Attributes
      class << self
        def typed_value_for_attribute_with_name(value, name)
          name = name.to_sym
          type_of_attribute(name).parse(value)
        end

        def type_of_attribute(attribute)
          ATTRIBUTE_TYPES[attribute.to_sym] || ATTRIBUTE_TYPE_DEFAULT
        end
      end

      ATTRIBUTE_TYPE_HASH    = HashAttribute
      ATTRIBUTE_TYPE_SET     = SetAttribute
      ATTRIBUTE_TYPE_BOOLEAN = BooleanAttribute
      ATTRIBUTE_TYPE_DEFAULT = StringAttribute

      ATTRIBUTE_TYPES = {
        class:    ATTRIBUTE_TYPE_SET,
        style:    ATTRIBUTE_TYPE_HASH,
        selected: ATTRIBUTE_TYPE_BOOLEAN,
        checked:  ATTRIBUTE_TYPE_BOOLEAN,
        disabled: ATTRIBUTE_TYPE_BOOLEAN,
        readonly: ATTRIBUTE_TYPE_BOOLEAN,
        multiple: ATTRIBUTE_TYPE_BOOLEAN,
      }

      extend Forwardable
      def_delegators :@attributes, :keys, :[], :[]=, :delete

      def initialize(attributes)
        @attributes = attributes
      end

      def [](attribute)
        @attributes[attribute.to_sym]
      end

      def []=(attribute, value)
        attribute = attribute.to_sym

        if self.class.type_of_attribute(attribute) == ATTRIBUTE_TYPE_BOOLEAN
          if value
            @attributes[attribute] = ""
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
