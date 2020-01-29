# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/application/behavior/data/lookup"
require "pakyow/application/behavior/data/serialization"
require "pakyow/application/helpers/data"

require "pakyow/data/object"

require "pakyow/data/sources/relational"

module Pakyow
  module Data
    class Framework < Pakyow::Framework(:data)
      def boot
        object.class_eval do
          definable :source, Sources::Relational, builder: -> (*args, **kwargs) {
            unless kwargs.key?(:adapter)
              kwargs[:adapter] = Pakyow.config.data.default_adapter
            end

            unless kwargs.key?(:connection)
              kwargs[:connection] = Pakyow.config.data.default_connection
            end

            unless kwargs.key?(:primary_id)
              kwargs[:primary_id] = true
            end

            unless kwargs.key?(:timestamps)
              kwargs[:timestamps] = true
            end

            return *args, **kwargs
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
