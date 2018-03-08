# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/core/framework"

require "pakyow/data/types"
require "pakyow/data/lookup"
require "pakyow/data/verifier"
require "pakyow/data/model"
require "pakyow/data/source"
require "pakyow/data/proxy"
require "pakyow/data/subscribers"
require "pakyow/data/verification"
require "pakyow/data/validations"
require "pakyow/data/errors"

module Pakyow
  module Data
    CONNECTION_TYPES = %i(sql memory)

    class Framework < Pakyow::Framework(:data)
      def boot
        if controller = app.const_get(:Controller)
          controller.class_eval do
            include Verification

            # Define the data we wish to verify.
            #
            verifies :params

            # Handle all invalid data errors as a bad request, by default.
            #
            handle Pakyow::InvalidData, as: :bad_request

            def data
              app.data
            end
          end
        end

        app.class_eval do
          aspect :models

          stateful :model, Model

          helper VerificationHelpers

          attr_reader :data

          after :initialize do
            models = state_for(:model).each_with_object({}) { |model, models_by_name|
              next if model.attributes.empty?

              models_by_name[model.__class_name.name] = model
            }

            # discover associations
            models.values.flatten.each do |model|
              model.associations[:has_many].each do |has_many_association|
                if associated_model = models.values.flatten.find { |potentially_associated_model|
                     potentially_associated_model.plural_name == has_many_association[:model]
                   }

                  associated_model.belongs_to(model.plural_name)
                end
              end
            end

            @data = Lookup.new(
              models,
              Subscribers.new(
                self,
                Pakyow.config.data.adapter,
                Pakyow.config.data.adapter_options
              )
            )
          end

          settings_for :data do
            setting :adapter_options, {}

            defaults :production do
              setting :adapter_options do
                { redis_prefix: ["pw", config.name].join("/") }
              end
            end
          end
        end
      end
    end

    module VerificationHelpers
      def self.included(base)
        base.extend ClassAPI
      end

      module ClassAPI
        # Perform input verification before one or more routes, identified by name.
        #
        # @see Pakyow::Data::Verifier
        #
        # @api public
        def verify(*names, &block)
          verification_method_name = :"verify_#{names.join("_")}"

          define_method verification_method_name do
            verify(&block)
          end

          action verification_method_name, only: names
        end
      end
    end
  end
end

Pakyow.module_eval do
  class << self
    attr_reader :database_containers

    def relation(name, adapter, connection)
      unless relation = container(adapter, connection).relations[name]
        raise ArgumentError, "Unknown database relation `#{name}' for adapter `#{adapter}', connection `#{connection}'"
      end

      relation
    end

    def container(adapter, connection)
      adapter ||= Pakyow.config.data.default_adapter
      unless container = Pakyow.database_containers.dig(adapter, connection)
        raise ArgumentError, "Unknown database container container for adapter `#{adapter}', connection `#{connection}'"
      end

      container
    end
  end

  # TODO: nest this under data
  settings_for :connections do
    Pakyow::Data::CONNECTION_TYPES.each do |type|
      setting type, {}
    end
  end

  settings_for :data do
    setting :default_adapter, :sql
    setting :logging, false
    setting :auto_migrate, true

    # TODO: nest these two under subscriptions
    setting :adapter, :memory
    setting :adapter_options, {}

    defaults :production do
      setting :adapter, :redis
      # TODO: use REDIS_PROVIDER/REDIS_URL with fallback
      setting :adapter_options, redis_url: "redis://127.0.0.1:6379", redis_prefix: "pw"
      setting :auto_migrate, false
    end
  end

  after :boot do
    @database_containers = Pakyow::Data::CONNECTION_TYPES.each_with_object({}) { |adapter_type, adapter_containers|
      connection_strings = Pakyow.config.connections.public_send(adapter_type)
      next if connection_strings.empty?
      require "pakyow/data/adapters/#{adapter_type}"

      adapter_containers[adapter_type] = connection_strings.each_with_object({}) do |(name, string), named_containers|
        # TODO: perform some validation on the connection string, instructing on the format
        config = ROM::Configuration.new(adapter_type, string)

        if Pakyow.config.data.logging
          config.gateways[:default].use_logger(Pakyow.logger)
        end

        models = apps.flat_map { |app|
          app.state_for(:model)
        }.select { |model|
          (model.adapter || Pakyow.config.data.default_adapter) == adapter_type && model.connection == name
        }

        models.each do |model|
          config.relation model.plural_name.to_sym do
            schema do
              model.attributes.each do |name, options|
                type = Pakyow::Data::Types.type_for(options[:type], adapter_type)

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
                attribute :"#{Pakyow::Support.inflector.singularize(belongs_to_association[:model])}_id", Pakyow::Data::Types.type_for(:integer, adapter_type).optional
              end

              if timestamps = model.timestamp_fields
                use :timestamps
                timestamps(*[timestamps[:update], timestamps[:create]].compact)
              end

              if setup_block = model.setup_block
                instance_exec(&setup_block)
              end
            end

            if model.queries_block
              class_eval(&model.queries_block)
            end

            model.attributes.each do |attribute_name, _options|
              define_method :"by_#{attribute_name}" do |value|
                map_with(:model).where(attribute_name => value)
              end
            end

            model.associations[:has_many].each do |has_many_association|
              define_method :"with_#{has_many_association[:model]}" do
                map_with(:model).combine(has_many_association[:model]).node(has_many_association[:model]) { |objects|
                  objects.map_with(:model)
                }
              end
            end

            model.associations[:belongs_to].each do |belongs_to_association|
              association_name = Pakyow::Support.inflector.singularize(belongs_to_association[:model]).to_sym
              define_method :"with_#{association_name}" do
                map_with(:model).combine(association_name).node(association_name) { |objects|
                  objects.map_with(:model)
                }
              end
            end
          end

          config.mappers do
            define model.plural_name do
              self.model model
              register_as :model
            end
          end

          config.commands model.plural_name do
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

        named_containers[name] = ROM.container(config)

        if Pakyow.config.data.auto_migrate && config.gateways[:default].respond_to?(:auto_migrate!)
          config.gateways[:default].auto_migrate!(config, inline: true)
        end
      end
    }
  end
end
