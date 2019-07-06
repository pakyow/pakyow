# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Reflection
    # @api private
    class Action
      attr_reader :name, :scope, :node, :view_path, :binding, :attributes, :nested, :parents

      def initialize(name:, scope:, node:, view_path:, binding: nil, attributes: [], nested: [], parents: [])
        @name, @scope, @node, @view_path, @binding, @attributes, @nested, @parents = normalize(name), scope, node, view_path, binding, attributes, nested, parents
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
