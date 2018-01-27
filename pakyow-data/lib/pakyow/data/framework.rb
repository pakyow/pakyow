# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/data/types"
require "pakyow/data/lookup"
require "pakyow/data/verifier"
require "pakyow/data/model"
require "pakyow/data/model_proxy"
require "pakyow/data/query"
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
            verifies :params

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

          before :freeze do
            models = state_for(:model).each_with_object({}) { |model, models_by_name|
              next if model.attributes.empty?

              models_by_name[model.__class_name.name] = model
            }

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
                { redis_prefix: ["pw", config.app.name].join("/") }
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
          before(*names) do
            verify(&block)
          end
        end
      end
    end
  end
end

Pakyow.module_eval do
  class << self
    # TODO: probably best as config
    attr_reader :database_containers
  end

  settings_for :connections do
    Pakyow::Data::CONNECTION_TYPES.each do |type|
      setting type, {}
    end
  end

  settings_for :data do
    setting :default_adapter, :sql
    setting :logging, false

    setting :adapter, :memory
    setting :adapter_options, {}

    defaults :production do
      setting :adapter, :redis
      setting :adapter_options, redis_url: "redis://127.0.0.1:6379", redis_prefix: "pw"
    end
  end

  after :boot do
    @database_containers = Pakyow::Data::CONNECTION_TYPES.each_with_object({}) { |adapter_type, adapter_containers|
      connection_strings = Pakyow.config.connections.public_send(adapter_type)
      next if connection_strings.empty?
      require "pakyow/data/adapters/#{adapter_type}"

      adapter_containers[adapter_type] = connection_strings.each_with_object({}) do |(name, string), named_containers|
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
          next if model.attributes.empty?

          config.relation model.__class_name.name do
            schema model.dataset do
              model.attributes.each do |name, options|
                attribute name, Pakyow::Data::Types.type_for(options[:type], adapter_type)
              end

              primary_key(*model._primary_key) if model._primary_key

              if timestamps = model._timestamps
                use :timestamps
                timestamps(*timestamps) unless timestamps.nil? || timestamps.empty?
              end

              if setup_block = model.setup_block
                instance_exec(&setup_block)
              end
            end
          end
        end

        # TODO: rename all our internal state since we aren't using containers
        named_containers[name] = ROM.container(config)

        # TODO: make this a config variable (e.g. do it only in development)
        config.gateways[:default].auto_migrate!(config, inline: true)
      end
    }
  end
end
