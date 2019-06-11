# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Reflection
    class Scope
      attr_reader :name, :parent, :actions, :attributes, :endpoints, :children

      def initialize(name, parent: nil)
        @name, @parent = normalize(name), parent
        @actions, @attributes, @endpoints, @children = [], [], [], []

        unless parent.nil?
          parent.children << self
        end
      end

      def named?(name)
        @name == normalize(name)
      end

      def action(name)
        @actions.find { |action|
          action.named?(name)
        }
      end

      def attribute(name)
        @attributes.find { |attribute|
          attribute.named?(name)
        }
      end

      def plural_name
        Support.inflector.pluralize(@name).to_sym
      end

      private

      def normalize(name)
        Support.inflector.singularize(name.to_s).to_sym
      end
    end
  end
end
