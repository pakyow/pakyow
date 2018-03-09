# frozen_string_literal: true

require "rom"

module Pakyow
  module Data
    class Container
      def initialize(adapter_type:, connection_name:, connection_string:)
        @adapter_type, @connection_name, @connection_string = adapter_type, connection_name, connection_string

        @config = ROM::Configuration.new(adapter_type, connection_string)

        if Pakyow.config.data.logging
          @config.gateways[:default].use_logger(Pakyow.logger)
        end

        @config.gateways[:default].use_logger($stdout)

        define!
        auto_migrate!
      end

      def container
        ROM.container(@config)
      end

      private

      def models
        @models ||= Pakyow.apps.flat_map { |app|
          app.state_for(:model)
        }.select { |model|
          (model.adapter || Pakyow.config.data.default_adapter) == @adapter_type && model.connection == @connection_name
        }
      end

      def define!
        models.each do |model|
          define_relation!(model)
          define_mappers!(model)
          define_commands!(model)
        end
      end

      def define_relation!(model)
        @config.relation(model.plural_name.to_sym).tap do |relation|
          define_relation_schema!(relation, model)
          define_relation_queries!(relation, model.queries_block)
          define_relation_queries_for_attributes!(relation, model.attributes)
          define_relation_queries_for_associations!(relation, model.associations)
        end
      end

      def define_relation_schema!(relation, model)
        local_adapter_type = @adapter_type

        relation.schema do
          model.attributes.each do |name, options|
            type = Pakyow::Data::Types.type_for(options[:type], local_adapter_type)

            if options[:nullable] && model.primary_key_field != name
              type = type.optional
            end

            if default_value = options[:default]
              type = type.default { default_value }
            end

            attribute name, type, null: options[:nullable]
          end

          if model.primary_key_field && model.attributes.keys.include?(model.primary_key_field)
            primary_key(model.primary_key_field)
          else
            # TODO: protect against defining an unknown field as a pk
          end

          associations do
            model.associations[:has_many].each do |has_many_association|
              has_many has_many_association[:model], view: has_many_association[:view]
            end

            model.associations[:belongs_to].each do |belongs_to_association|
              belongs_to belongs_to_association[:model], as: Pakyow::Support.inflector.singularize(belongs_to_association[:model]).to_sym
            end
          end

          model.associations[:belongs_to].each do |belongs_to_association|
            attribute :"#{Pakyow::Support.inflector.singularize(belongs_to_association[:model])}_id", Pakyow::Data::Types.type_for(:integer, local_adapter_type).optional
          end

          if timestamps = model.timestamp_fields
            use :timestamps
            timestamps(*[timestamps[:update], timestamps[:create]].compact)
          end

          if setup_block = model.setup_block
            instance_exec(&setup_block)
          end
        end
      end

      def define_relation_queries!(relation, queries_block)
        relation.class_eval do
          if queries_block
            class_eval(&queries_block)
          end
        end
      end

      def define_relation_queries_for_attributes!(relation, attributes)
        relation.class_eval do
          attributes.each do |attribute_name, _options|
            define_method :"by_#{attribute_name}" do |value|
              map_with(:model).where(attribute_name => value)
            end
          end
        end
      end

      def define_relation_queries_for_associations!(relation, associations)
        relation.class_eval do
          associations[:has_many].each do |has_many_association|
            define_method :"with_#{has_many_association[:model]}" do
              map_with(:model).combine(has_many_association[:model]).node(has_many_association[:model]) { |objects|
                objects.map_with(:model)
              }
            end
          end

          associations[:belongs_to].each do |belongs_to_association|
            association_name = Pakyow::Support.inflector.singularize(belongs_to_association[:model]).to_sym
            define_method :"with_#{association_name}" do
              map_with(:model).combine(association_name).node(association_name) { |objects|
                objects.map_with(:model)
              }
            end
          end
        end
      end

      def define_mappers!(model)
        @config.mappers do
          define model.plural_name do
            self.model model
            register_as :model
          end
        end
      end

      def define_commands!(model)
        @config.commands model.plural_name do
          define :create do
            result :one

            if timestamps = model.timestamp_fields
              use :timestamps
              timestamp(*[timestamps[:update], timestamps[:create]].compact)
            end
          end

          define :update do
            result :many

            if timestamps = model.timestamp_fields
              use :timestamps
              timestamp timestamps[:update]
            end
          end

          define :delete do
            result :many
          end
        end
      end

      def auto_migrate!
        if Pakyow.config.data.auto_migrate && @config.gateways[:default].respond_to?(:auto_migrate!)
          @config.gateways[:default].auto_migrate!(@config, inline: true)
        end
      end
    end
  end
end
