# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/data/object"
require "pakyow/data/helpers"

require "pakyow/data/config"
require "pakyow/data/behavior/lookup"
require "pakyow/data/behavior/serialization"

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

          register_helper :active, Helpers

          include Config
          include Behavior::Lookup
          include Behavior::Serialization
        end
      end
    end
  end
end
