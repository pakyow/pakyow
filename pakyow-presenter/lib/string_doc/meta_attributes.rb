# frozen_string_literal: true

class StringDoc
  # Lets two or more node's attributes to be manipulated together. Used by {StringDoc::MetaNode}.
  #
  # @api private
  class MetaAttributes
    def initialize(attributes)
      @attributes = attributes
    end

    def []=(key, value)
      @attributes.each do |attributes|
        attributes[key] = value
      end
    end

    def [](key)
      @attributes[0][key]
    end

    def delete(key)
      @attributes.each do |attributes|
        attributes.delete(key)
      end
    end

    def key?(key)
      @attributes.any? { |attributes|
        attributes.key?(key)
      }
    end

    def each(&block)
      @attributes.each do |attributes|
        attributes.each(&block)
      end
    end

    # @api private
    def wrap
      @attributes.each do |attributes|
        attributes.each do |key, value|
          yield value, key
        end
      end
    end
  end
end
