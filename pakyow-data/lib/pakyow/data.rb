# frozen_string_literal: true

require "pakyow"
require "pakyow/core"

require "rom"

module Pakyow
  module Data
    CONNECTION_TYPES = %i(sql memory)

    def self.included(base)
      load_into(base)
    end

    def self.load_into(app_class)
      app_class.class_eval do
        concern :data

        stateful :model, Pakyow::Data::Model

        attr_reader :data_model_lookup

        before :freeze do
          models = state_for(:model).each_with_object({}) { |model, models_by_name|
            next if model.attributes.empty?

            models_by_name[model.name] = model
          }

          @data_model_lookup = Data::Lookup.new(
            models,
            Data::SubscriberStore.new(
              config.app.name,
              Pakyow.config.data.subscription_adapter,
              Pakyow.config.data.subscription_adapter_options
            )
          )
        end
      end
    end
  end
end

require "pakyow/data/types"
require "pakyow/data/lookup"
require "pakyow/data/verifier"
require "pakyow/data/model"
require "pakyow/data/model_proxy"
require "pakyow/data/query"
require "pakyow/data/subscriber_store"
require "pakyow/data/validations"
require "pakyow/data/errors"

require "pakyow/data/ext/pakyow/environment"
require "pakyow/data/ext/pakyow/core/controller"
require "pakyow/data/ext/pakyow/core/router"

Pakyow.register_framework :data, Pakyow::Data
