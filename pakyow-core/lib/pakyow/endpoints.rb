# frozen_string_literal: true

require "forwardable"

module Pakyow
  # Lookup for endpoints.
  #
  class Endpoints
    include Enumerable

    extend Forwardable
    def_delegator :@endpoints, :each

    def initialize
      @endpoints = []
    end

    # Adds an endpoint.
    #
    def <<(endpoint)
      @endpoints << endpoint
    end

    def load(object_with_endpoints)
      if object_with_endpoints.respond_to?(:endpoints)
        object_with_endpoints.endpoints.each do |endpoint|
          self << endpoint
        end
      end
    end

    # Builds the path to a named route.
    #
    # @example Build the path to the +new+ route within the +post+ group:
    #   path(:post_new)
    #   # => "/posts/new"
    #
    # @example Build the path providing a value for +post_id+:
    #   path(:post_edit, post_id: 1)
    #   # => "/posts/1/edit"
    #
    def path(name, **params)
      name = name.to_sym
      found = @endpoints.find { |endpoint|
        endpoint.name == name
      }

      found&.path(**params)
    end

    # Builds the path to a route, following a trail of names.
    #
    # @example Build the path to the +new+ route within the +post+ group:
    #   path_to(:post, :new)
    #   # => "/posts/new"
    #
    # @example Build the path providing a value for +post_id+:
    #   path_to(:post, :edit, post_id: 1)
    #   # => "/posts/1/edit"
    #
    def path_to(*names, **params)
      path(names.join("_").to_sym, **params)
    end
  end

  class Endpoint
    attr_reader :name, :builder

    def initialize(name:, builder:)
      @name, @builder = name.to_sym, builder
    end

    def path(**params)
      @builder.call(**params)
    end
  end
end
