# frozen_string_literal: true

require "pakyow/support/makeable"

module Pakyow
  module Data
    class Model
      extend Support::Makeable
      extend Support::DeepFreeze
      unfreezable :relation

      def initialize(relation)
        @relation = relation
      end

      def name
        self.class.name
      end

      def qualifications(query_name)
        self.class.qualifications(query_name)
      end

      def method_missing(method_name, *args, &block)
        if @relation.respond_to?(method_name)
          @relation.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        @relation.respond_to?(method_name) || super
      end

      # TODO: commands need to support:
      #   * passing a mapper
      #   * setting the result type (one vs many)
      #   * using plugins, if that's a thing to support

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
        @relation.to_a
      end

      def by_id(id)
        @relation.by_pk(id)
      end

      class << self
        attr_reader :name, :adapter, :connection, :setup_block

        def make(name, adapter: nil, connection: :default, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, adapter: adapter, connection: connection, attributes: {}, **kwargs, &block)
        end

        # TODO: default values?
        def attribute(name, type = :string)
          attributes[name.to_sym] = {
            type: type
          }
        end

        def dataset
          @dataset || @name
        end

        def attributes
          @attributes ||= {}
        end

        def timestamps(*fields)
          @timestamps = fields
        end

        def primary_id
          primary_key :id
          attribute :id, :serial
        end

        def _timestamps
          @timestamps
        end

        def command(name, &block)
          # TODO: define command
        end

        def primary_key(*names)
          @primary_key = names
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
      end
    end
  end
end
