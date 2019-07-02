# frozen_string_literal: true

require "pakyow/support/inflector"

module Pakyow
  module Reflection
    class Scope
      attr_reader :name, :parents, :actions, :children
      attr_writer :parent

      def initialize(name)
        @name = normalize(name)
        @parents, @actions, @attributes, @children = [], [], { form: [], view: [] }, []
      end

      def add_parent(parent)
        unless @parents.include?(parent)
          @parents << parent
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

      def attribute(name, type:)
        @attributes[type].find { |attribute|
          attribute.named?(name)
        }
      end

      def add_attribute(attribute, type:)
        @attributes[type] << attribute
      end

      def attributes
        # TODO: In addition to finding view attributes, should we be finding view associations?
        #
        @attributes[:form].concat(@attributes[:view]).uniq { |attribute|
          attribute.name
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
