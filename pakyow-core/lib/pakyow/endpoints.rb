# frozen_string_literal: true

require "forwardable"

require "pakyow/support/deprecatable"

module Pakyow
  # Lookup for endpoints.
  #
  class Endpoints
    include Enumerable

    extend Forwardable
    def_delegator :@endpoints, :each

    extend Support::Deprecatable

    def initialize(prefix: "/")
      @prefix = prefix
      @endpoints = []
    end

    def build(name:, method:, builder:, prefix: "/")
      self << Endpoint.new(name: name, method: method, builder: builder, prefix: File.join(@prefix, prefix))
    end

    def find(name:)
      @endpoints.find { |endpoint|
        endpoint.name == name
      }
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
    def path(name, hashlike_object = nil, **params)
      endpoint_with_name(name)&.path(hashlike_object, **params)
    end

    def method(name)
      endpoint_with_name(name)&.method
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

    private

    def endpoint_with_name(name)
      name = name.to_sym
      @endpoints.find { |endpoint|
        endpoint.name == name
      }
    end
  end

  require "pakyow/support/core_refinements/string/normalization"

  class Endpoint
    using Support::Refinements::String::Normalization

    extend Forwardable
    def_delegators :@builder, :params, :source_location

    attr_reader :name, :method, :builder, :prefix

    def initialize(name:, method:, builder:, prefix: "/")
      @name, @method, @builder, @prefix = name.to_sym, method.to_sym, builder, prefix
    end

    def path(hashlike_object = nil, **params)
      String.normalize_path(
        File.join(@prefix, @builder.call(**(hashlike_object || params).to_h).to_s)
      )
    end
  end
end
