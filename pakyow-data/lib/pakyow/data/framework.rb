# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/core/framework"

require "pakyow/data/types"
require "pakyow/data/lookup"
require "pakyow/data/model"
require "pakyow/data/source"
require "pakyow/data/proxy"
require "pakyow/data/subscribers"
require "pakyow/data/errors"
require "pakyow/data/container"

module Pakyow
  module Data
    SUPPORTED_CONNECTION_TYPES = %i(sql)

    class Framework < Pakyow::Framework(:data)
      def boot
        if controller = app.const_get(:Controller)
          controller.class_eval do
            def data
              app.data
            end
          end
        end

        app.class_eval do
          stateful :model, Model

          # Autoload models from the `models` directory.
          #
          aspect :models

          # Data lookup object.
          #
          attr_reader :data

          after :initialize do
            define_inverse_associations!

            @data = Lookup.new(
              state_for(:model),
              Subscribers.new(
                self,
                Pakyow.config.data.subscriptions.adapter,
                Pakyow.config.data.subscriptions.adapter_options
              )
            )
          end

          private

          # Defines inverse associations. For example, this method would define
          # a +belongs_to :post+ relationship on the +:comment+ model, when the
          # +:post+ model +has_many :comments+.
          #
          def define_inverse_associations!
            state_for(:model).each do |model|
              model.associations[:has_many].each do |has_many_association|
                if associated_model = state_for(:model).flatten.find { |potentially_associated_model|
                     potentially_associated_model.plural_name == has_many_association[:model]
                   }

                  associated_model.belongs_to(model.plural_name)
                end
              end
            end
          end
        end
      end
    end
  end
end

Pakyow.module_eval do
  class << self
    # @api private
    attr_reader :database_containers

    # @api private
    def relation(name, adapter, connection)
      unless relation = container(adapter, connection).relations[name]
        raise ArgumentError, "Unknown database relation `#{name}' for adapter `#{adapter}', connection `#{connection}'"
      end

      relation
    end

    # @api private
    def container(adapter, connection)
      adapter ||= Pakyow.config.data.default_adapter
      unless container = Pakyow.database_containers.dig(adapter, connection)
        raise ArgumentError, "Unknown database container container for adapter `#{adapter}', connection `#{connection}'"
      end

      container
    end
  end

  settings_for :data do
    setting :default_adapter, :sql
    setting :logging, false
    setting :auto_migrate, true

    defaults :production do
      setting :auto_migrate, false
    end

    settings_for :subscriptions do
      setting :adapter, :memory
      setting :adapter_options, {}

      defaults :production do
        setting :adapter, :redis
        setting :adapter_options, redis_url: ENV["REDIS_URL"] || "redis://127.0.0.1:6379", redis_prefix: "pw"
      end
    end

    settings_for :connections do
      Pakyow::Data::SUPPORTED_CONNECTION_TYPES.each do |type|
        setting type, {}
      end
    end
  end

  after :boot do
    @database_containers = {}
    Pakyow::Data::SUPPORTED_CONNECTION_TYPES.each do |adapter|
      require "pakyow/data/adapters/#{adapter}"

      @database_containers[adapter] = {}
      Pakyow.config.data.connections.public_send(adapter).each do |connection_name, connection_string|
        @database_containers[adapter][connection_name] = Pakyow::Data::Container.new(
          adapter_type: adapter,
          connection_name: connection_name,
          connection_string: connection_string
        ).container
      end
    end
  end
end
