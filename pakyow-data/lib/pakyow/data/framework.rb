# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/app/config/data"
require "pakyow/app/behavior/data/lookup"
require "pakyow/app/behavior/data/serialization"
require "pakyow/app/helpers/data"

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

          register_helper :active, Pakyow::App::Helpers::Data

          include App::Config::Data
          include App::Behavior::Data::Lookup
          include App::Behavior::Data::Serialization
        end
      end
    end
  end
end
