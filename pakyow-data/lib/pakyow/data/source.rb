# frozen_string_literal: true

module Pakyow
  module Data
    class Source < SimpleDelegator
      attr_reader :model

      def initialize(model:, relation:)
        @model = model
        __setobj__(relation)
      end

      def command?(maybe_command_name)
        %i[create update delete].include?(maybe_command_name)
      end

      def create(values)
        set_ids_for_belongs_to_associations!(values)
        command(:create).call(values)
      end

      def update(values)
        set_ids_for_belongs_to_associations!(values)
        command(:update).call(values)
      end

      def delete
        command(:delete).call
      end

      def all
        if mappable?
          map_with(:model).to_a
        else
          to_a
        end
      end

      def one
        if mappable?
          map_with(:model).one
        else
          super
        end
      end

      def each(&block)
        map_with(:model).each(&block)
      end

      def empty?
        count == 0
      end

      private

      def set_ids_for_belongs_to_associations!(values)
        @model.associations[:belongs_to].each do |association|
          association = Support.inflector.singularize(association[:model]).to_sym
          if values.key?(association)
            values[:"#{association}_id"] = values[association][:id]
          end
        end
      end

      UNMAPPABLE = [
        ROM::Relation::Composite
      ].freeze

      def mappable?
        !UNMAPPABLE.include?(__getobj__.class)
      end
    end
  end
end
