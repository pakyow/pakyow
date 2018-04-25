# frozen_string_literal: true

require "pakyow/support/makeable"
require "pakyow/support/class_state"

module Pakyow
  module Data
    # Represents a data source through which you interact with a persistence
    # layer such as a sql database, redis, or http. Defines the schema, queries,
    # and other adapter-specific metadata (e.g. sql table). All data access
    # occurs through queries. Mutations are handled through commands.
    #
    # Each adapter provides its own interface for interacting with the underlying
    # persistence layer. For example, the sql adapter exposes +Sequel::Dataset+
    # provided by the fantastic Sequel library.
    #
    # Sources blindly accept input and do not implement validation, though input
    # will be coerced to the appropriate type. Use the input verifier pattern to
    # verify and validate input before passing it to a data source
    # (@see Pakyow::Verifier).
    #
    # Queries always return a {Pakyow::Data::Proxy} object containing the value
    # returned as well as metadata describing the query. Access to the
    # underlying value is provided through methods such as +first+, +all+, and
    # +each+ (@see Pakyow::Data::Proxy).
    #
    # Sources accept an optional +object_map+ for mapping values to instances of
    # +Pakyow::Data::Object+. If an object matching the source name is found,
    # instances of that object will be returned as results.
    #
    # @example
    #   source :posts, adapter: :sql, connection: :default do
    #     table :posts
    #
    #     primary_id
    #     timestamps
    #
    #     attribute :title, :string
    #
    #     command :create do |params|
    #       insert(params)
    #     end
    #
    #     def by_id(id)
    #       where(id: id)
    #     end
    #   end
    #
    #   data.posts.by_id(1).first
    #
    class Source < SimpleDelegator
      def initialize(dataset, object_map: {})
        __setobj__(dataset)
        @object_map = object_map
        @wrap_as = self.class.singular_name
      end

      def as(object)
        @wrap_as = object
        self
      end

      def each
        self.class.each(__getobj__) do |result|
          yield wrap(result)
        end
      end

      def to_a
        self.class.to_a(__getobj__).map { |result|
          wrap(result)
        }
      end

      def one
        wrap(self.class.one(__getobj__))
      end

      def command?(maybe_command_name)
        # TODO: hook this up for real

        false
      end

      def query?(maybe_query_name)
        self.class.queries.include?(maybe_query_name)
      end

      RESULT_METHODS = %i(each to_a one).freeze
      def result?(maybe_result_name)
        RESULT_METHODS.include?(maybe_result_name)
      end

      MODIFIER_METHODS = %i(as).freeze
      def modifier?(maybe_modifier_name)
        MODIFIER_METHODS.include?(maybe_modifier_name)
      end

      private

      def wrap(result)
        @object_map.fetch(@wrap_as, Object).new(result)
      end

      extend Support::Makeable
      extend Support::ClassState

      class_state :timestamp_fields
      class_state :primary_key_field
      class_state :attributes, default: {}
      class_state :qualifications, default: {}
      class_state :associations, default: { has_many: [], belongs_to: [] }

      class << self
        attr_reader :name, :adapter, :connection

        def make(name, adapter: Pakyow.config.data.default_adapter, connection: Pakyow.config.data.default_connection, state: nil, parent: nil, **kwargs, &block)
          super(name, state: state, parent: parent, adapter: adapter, connection: connection, attributes: {}, **kwargs, &block).tap { |source|
            source.prepend(
              Module.new do
                source.queries.each do |query|
                  define_method query do |*args, &block|
                    self.class.new(super(*args, &block), object_map: @object_map)
                  end
                end
              end
            )

            source.extend Pakyow.connection(adapter, connection).adapter.class.const_get("DatasetMethods")
          }
        end

        def queries
          instance_methods - superclass.instance_methods
        end

        def timestamps(create: :created_at, update: :updated_at)
          @timestamp_fields = {
            create: create,
            update: update
          }

          attribute create, :datetime
          attribute update, :datetime
        end

        def primary_id
          primary_key :id
          attribute :id, :serial
        end

        def primary_key(field)
          @primary_key_field = field
        end

        def attribute(name, type = :string, default: nil, nullable: true)
          attributes[name.to_sym] = {
            type: type,
            default: default,
            nullable: nullable
          }

          qualify_query_for_attribute!(name)
        end

        def subscribe(query_name, qualifications)
          @qualifications[query_name] = qualifications
        end

        def qualifications(query_name)
          @qualifications.dig(query_name) || {}
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
          Support.inflector.pluralize(__class_name.name).to_sym
        end

        def singular_name
          Support.inflector.singularize(__class_name.name).to_sym
        end

        private

        def qualify_query_for_attribute!(attribute_name)
          subscribe :"by_#{attribute_name}", attribute_name => :__arg0__
        end
      end
    end
  end
end

# module Pakyow
#   module Data
#     class Source < SimpleDelegator
#       attr_reader :model

#       def initialize(model:, relation:)
#         @model = model
#         __setobj__(relation)
#       end

#       def command?(maybe_command_name)
#         %i[create update delete].include?(maybe_command_name)
#       end

#       def create(values)
#         set_ids_for_belongs_to_associations!(values)
#         command(:create).call(values)
#       end

#       def update(values)
#         set_ids_for_belongs_to_associations!(values)
#         command(:update).call(values)
#       end

#       def delete
#         command(:delete).call
#       end

#       def all
#         if mappable?
#           map_with(:model).to_a
#         else
#           to_a
#         end
#       end

#       def one
#         if mappable?
#           map_with(:model).one
#         else
#           super
#         end
#       end

#       def each(&block)
#         map_with(:model).each(&block)
#       end

#       def empty?
#         count == 0
#       end

#       private

#       def set_ids_for_belongs_to_associations!(values)
#         @model.associations[:belongs_to].each do |association|
#           association = Support.inflector.singularize(association[:model]).to_sym
#           if values.key?(association)
#             values[:"#{association}_id"] = values[association][:id]
#           end
#         end
#       end

#       UNMAPPABLE = [
#         ROM::Relation::Composite
#       ].freeze

#       def mappable?
#         !UNMAPPABLE.include?(__getobj__.class)
#       end
#     end
#   end
# end
