# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Reflection
    class Attribute
      attr_reader :name, :type

      def initialize(name, type:, required: false)
        @name, @type, @required = normalize(name), type, required
      end

      def named?(name)
        @name == normalize(name)
      end

      def required?
        @required == true
      end

      private

      def normalize(name)
        name.to_s.to_sym
      end
    end
  end
end
