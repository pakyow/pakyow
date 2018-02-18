# frozen_string_literal: true

require "pakyow/support/makeable"
require "pakyow/support/class_state"

module Pakyow
  module Data
    # Provides access to a type of data.
    #
    # Implemented as a delegator to {Rom::Relation}.
    #
    class Model < SimpleDelegator
      extend Support::Makeable

      def command?(maybe_command_name)
        %i[create update delete].include?(maybe_command_name)
      end

      def create(values)
        values[:created_at] ||= Time.now
        values[:updated_at] ||= Time.now

        command(:create).call(values, result: :one)
      end

      def update(values)
        command(:update, result: :many).call(values)
      end

      def delete
        command(:delete, result: :many).call
      end

      def all
        to_a
      end

      def by_id(id)
        by_pk(id)
      end

      def empty?
        count == 0
      end

      extend Support::ClassState
      class_state :attributes, inheritable: true, default: {}
      class_state :associations, inheritable: true, default: { has_many: [], belongs_to: [] }

      class << self
        attr_reader :name, :adapter, :connection, :setup_block, :associations

        def make(name, adapter: nil, connection: :default, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, adapter: adapter, connection: connection, attributes: {}, **kwargs, &block)
        end

        # TODO: default values?
        def attribute(name, type = :string)
          attributes[name.to_sym] = {
            type: type
          }
        end

        def timestamps(*fields)
          @timestamps = fields
        end

        def _timestamps
          @timestamps
        end

        def command(name, &block)
          # TODO: define command
        end

        def primary_id
          primary_key :id
          attribute :id, :serial
        end

        def primary_key(field)
          @primary_key = field
        end

        def _primary_key
          @primary_key
        end

        def subscribe(query_name, qualifications)
          (@qualifications ||= {})[query_name] = qualifications
        end

        def qualifications(query_name)
          @qualifications&.dig(query_name) || {}
        end

        def setup(&block)
          @setup_block = block
        end

        # rubocop:disable Naming/PredicateName
        def has_many(relation)
          @associations[:has_many] << relation
        end
        # rubocop:enable Naming/PredicateName

        def belongs_to(relation)
          @associations[:belongs_to] << relation
        end
      end
    end
  end
end
