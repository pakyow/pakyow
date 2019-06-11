# frozen_string_literal: true

module Pakyow
  module Reflection
    class Endpoint
      attr_reader :view_path, :scope, :binding, :channel, :parent, :children

      def initialize(view_path, scope:, binding:, channel: nil, parent: nil)
        @view_path, @scope, @binding, @channel, @parent = view_path, scope, binding, channel, parent
        @children = []

        unless parent.nil?
          parent.children << self
        end
      end
    end
  end
end
