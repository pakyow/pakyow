# frozen_string_literal: true

module Pakyow
  class App
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
