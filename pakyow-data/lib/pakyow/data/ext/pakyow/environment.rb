module Pakyow
  class << self
    attr_reader :data_model_lookup
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
  end

  after :boot do
    model_instances = {}

    # TODO: we need to store and lookup models by app to avoid collisions

    @database_containers = Pakyow::Data::CONNECTION_TYPES.each_with_object({}) { |adapter_type, adapter_containers|
      connection_strings = Pakyow.config.connections.public_send(adapter_type)
      next if connection_strings.empty?
      require "pakyow/data/adapters/#{adapter_type}"

      adapter_containers[adapter_type] = connection_strings.each_with_object({}) do |(name, string), named_containers|
        models = apps.flat_map { |app|
          app.state_for(:model)
        }.select { |model|
          (model.adapter || Pakyow.config.data.default_adapter) == adapter_type && model.connection == name
        }

        config = ROM::Configuration.new(adapter_type, string)

        models.each do |model|
          next if model.attributes.empty?

          config.relation model.name do
            schema model._dataset do
              model.attributes.each do |name, options|
                attribute name, Data::Types.type_for(options[:type], adapter_type)
              end

              primary_key(*model._primary_key) if model._primary_key

              if timestamps = model._timestamps
                use :timestamps
                timestamps(*timestamps) unless timestamps.nil? || timestamps.empty?
              end
            end
          end
        end

        if Pakyow.config.data.logging
          config.gateways[:default].use_logger(Pakyow.logger)
        end

        # TODO: rename all our internal state since we aren't using containers
        named_containers[name] = ROM.container(config)

        # TODO: make this a config variable (e.g. do it only in development)
        config.gateways[:default].auto_migrate!(config, inline: true)

        models.each do |model|
          next if model.attributes.empty?
          next if model_instances.key?(model.name)
          model_instances[model.name] = model.new(named_containers[name].relations[model.name])
        end
        # unless model_instances.key?(model.name)
        #     model_instances[model.name] = model.new(relation.new(relation.dataset))
        #   end
      end
    }

    @data_model_lookup = Data::Lookup.new(model_instances)
  end
end
