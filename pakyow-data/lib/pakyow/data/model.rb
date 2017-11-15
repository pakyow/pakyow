require "pakyow/support/class_maker"

module Pakyow
  module Data
    class Model
      extend Support::ClassMaker
      extend Support::DeepFreeze
      unfreezable :relation

      def initialize(relation)
        @relation = relation
      end

      def method_missing(method_name, *args)
        if @relation.respond_to?(method_name)
          @relation.send(method_name, *args)
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
        [:create, :update, :delete].include?(maybe_command_name)
      end

      def create(values)
        values[:created_at] ||= Time.now
        values[:updated_at] ||= Time.now
        command(:create).call(values)
      end

      def update(values)
        command(:update).call(values)
      end

      def delete
        command(:delete).call
      end

      def all
        @relation.to_a
      end

      # TODO: trigger mutations on the right objects
      # pass the mutated data to the mutation callback
      # this way we know exactly what changed
      #
      # how will ui know how to qualify the subscription?
      # could we do it purely based on presentable ids?
      # if we cache the results of a query, then yes
      #
      # problem is it doesn't always work... for example
      # if present a limited number of objects we'd update
      # when one of them changed, but not when the set did
      # e.g. presenting only the first post on the homepage
      # when a new post is published, it should change

      class << self
        attr_reader :name, :adapter, :connection

        def make(name, adapter: nil, connection: :default, state: nil, parent: nil, &block)
          klass, name = class_const_for_name(::Class.new(self), name)

          klass.class_eval do
            @name = name
            @state = state
            @adapter = adapter
            @connection = connection

            # TODO: find a pattern for this:
            @attributes = {}
            class_eval(&block) if block
          end

          klass
        end

        # TODO: default values?
        def attribute(name, type = :string)
          attributes[name.to_sym] = {
            type: type
          }
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

        def dataset(name)
          @dataset = name
        end

        def _dataset
          @dataset
        end
      end
    end
  end
end
