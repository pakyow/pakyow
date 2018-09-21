# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/data/source"
require "pakyow/data/object"
require "pakyow/data/helpers"

require "pakyow/data/behavior/lookup"

module Pakyow
  module Data
    class Framework < Pakyow::Framework(:data)
      def boot
        object.class_eval do
          isolate Source
          isolate Object

          stateful :source, isolated(:Source)
          stateful :object, isolated(:Object)

          # Autoload sources from the `sources` directory.
          #
          aspect :sources

          # Autoload objects from the `objects` directory.
          #
          aspect :objects

          register_helper :active, Helpers

          include Behavior::Lookup
        end
      end
    end
  end
end
