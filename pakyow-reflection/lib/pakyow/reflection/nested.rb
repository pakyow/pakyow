# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Reflection
    # @api private
    class Nested
      attr_reader :name, :attributes, :nested

      def initialize(name, attributes: [], nested: [])
        @name, @attributes, @nested = normalize(name), attributes, nested
      end

      def named?(name)
        @name == normalize(name)
      end

      def plural_name
        Support.inflector.pluralize(@name).to_sym
      end

      private

      def normalize(name)
        name.to_s.to_sym
      end
    end
  end
end
