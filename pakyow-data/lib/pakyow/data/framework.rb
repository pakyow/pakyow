# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Data
    class Framework < Pakyow::Framework(:data)
      def boot
        require "pakyow/application/behavior/data/lookup"
        require "pakyow/application/behavior/data/serialization"
        require "pakyow/application/helpers/data"

        require "pakyow/validations/data/unique"

        require "pakyow/data/object"
        require "pakyow/data/sources/relational"

        object.class_eval do
          definable :source, Sources::Relational, builder: -> (*namespace, object_name, **opts) {
            unless opts.key?(:adapter)
              opts[:adapter] = Pakyow.config.data.default_adapter
            end

            unless opts.key?(:connection)
              opts[:connection] = Pakyow.config.data.default_connection
            end

            unless opts.key?(:primary_id)
              opts[:primary_id] = true
            end

            unless opts.key?(:timestamps)
              opts[:timestamps] = true
            end

            return namespace, object_name, opts
          }

          definable :object, Object

          # Autoload sources from the `sources` directory.
          #
          aspect :sources

          # Autoload objects from the `objects` directory.
          #
          aspect :objects

          register_helper :active, Pakyow::Application::Helpers::Data

          configurable :data do
            configurable :subscriptions do
              setting :adapter_settings, {}
              setting :version

              defaults :production do
                setting :adapter_settings do
                  { key_prefix: [Pakyow.config.redis.key_prefix, config.name].join("/") }
                end
              end
            end
          end

          include Application::Behavior::Data::Lookup
          include Application::Behavior::Data::Serialization
        end
      end
    end
  end
end
