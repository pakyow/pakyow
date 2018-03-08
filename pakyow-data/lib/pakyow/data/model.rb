# frozen_string_literal: true

require "forwardable"

require "pakyow/support/indifferentize"
require "pakyow/support/inflector"
require "pakyow/support/makeable"
require "pakyow/support/class_state"

module Pakyow
  module Data
    # Provides access to a type of data.
    #
    # Implemented as a delegator to {Rom::Relation}.
    #
    class Model
      using Support::Indifferentize

      extend Forwardable
      def_delegators :@values, :[], :include?, :keys

      attr_reader :values

      def initialize(values)
        @values = values.indifferentize
        @values.freeze
      end

      def to_h
        @values
      end

      def method_missing(name, *)
        @values[name]
      end

      def respond_to_missing?(name, *)
        @values.include?(name)
      end

      extend Support::Makeable
      extend Support::ClassState

      class_state :queries_block
      class_state :timestamp_fields
      class_state :primary_key_field
      class_state :attributes, default: {}
      class_state :qualifications, default: {}
      class_state :associations, default: { has_many: [], belongs_to: [] }

      class << self
        attr_reader :name, :adapter, :connection, :setup_block, :associations

        def make(name, adapter: nil, connection: :default, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, adapter: adapter, connection: connection, attributes: {}, **kwargs, &block)
        end

        def queries(&block)
          @queries_block = block
        end

        def attribute(name, type = :string, default: nil, nullable: true)
          attributes[name.to_sym] = {
            type: type,
            default: default,
            nullable: nullable
          }

          qualify_query_for_attribute!(name)
        end

        def timestamps(create: :created_at, update: :updated_at)
          @timestamp_fields = {
            create: create,
            update: update
          }
        end

        def command(name, &block)
          # TODO: define command
        end

        def primary_id
          primary_key :id
          attribute :id, :serial
        end

        def primary_key(field)
          @primary_key_field = field
        end

        def subscribe(query_name, qualifications)
          @qualifications[query_name] = qualifications
        end

        def qualifications(query_name)
          @qualifications.dig(query_name) || {}
        end

        def setup(&block)
          @setup_block = block
        end

        # rubocop:disable Naming/PredicateName
        def has_many(model, view: nil)
          @associations[:has_many] << {
            model: model,
            view: view
          }
        end
        # rubocop:enable Naming/PredicateName

        def belongs_to(model)
          @associations[:belongs_to] << {
            model: Support.inflector.pluralize(model).to_sym
          }
        end

        def plural_name
          @plural_name ||= Support.inflector.pluralize(__class_name.name).to_sym
        end

        private

        def qualify_query_for_attribute!(attribute_name)
          subscribe :"by_#{attribute_name}", attribute_name => :__arg0__
        end
      end
    end
  end
end
