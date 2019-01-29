# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Reflection
    class Action
      attr_reader :name, :view_path, :channel, :attributes, :nested

      def initialize(name, view_path:, channel: [], attributes: [], nested: [])
        @name, @view_path, @channel, @attributes, @nested = normalize(name), view_path, channel, attributes, nested
      end

      def named?(name)
        @name == normalize(name)
      end

      private

      def normalize(name)
        Support.inflector.singularize(name.to_s).to_sym
      end
    end
  end
end
