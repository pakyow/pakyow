# frozen_string_literal: true

require "forwardable"

module Pakyow
  class App
    module Helpers
      # Convenience methods for interacting with the app object.
      #
      module App
        extend Forwardable

        attr_reader :app

        # @!method config
        #   Delegates to {app}.
        #
        #   @see App#config
        def_delegators :app, :config

        # @!method path
        #   @return builds the path to a named route (see {Paths#path})
        #
        # @!method path_to
        #   @return builds the path to a route, following a trail of names (see {Paths#path_to})
        def_delegators :"app.endpoints", :path, :path_to
      end
    end
  end
end
