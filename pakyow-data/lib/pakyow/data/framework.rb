# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/application/config/data"
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
          isolate Sources::Relational
          isolate Object

          stateful :source, isolated(:Relational)
          stateful :object, isolated(:Object)

          # Autoload sources from the `sources` directory.
          #
          aspect :sources

          # Autoload objects from the `objects` directory.
          #
          aspect :objects

          register_helper :active, Pakyow::Application::Helpers::Data

          include Application::Config::Data
          include Application::Behavior::Data::Lookup
          include Application::Behavior::Data::Serialization
        end
      end
    end
  end
end
