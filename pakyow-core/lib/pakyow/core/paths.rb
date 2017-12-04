# frozen_string_literal: true

module Pakyow
  # Lookup for app paths.
  #
  class Paths
    def initialize
      @objects_with_paths = []
    end

    # Adds an object with paths.
    #
    def <<(object_with_paths)
      @objects_with_paths << object_with_paths
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
      path_to(*name.to_s.split("_").map(&:to_sym), **params)
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
      matched_objects = @objects_with_paths.reject { |object_to_match|
        object_to_match.name.nil? || object_to_match.name != names.first
      }

      matched_objects.each do |matched_object|
        if path = matched_object.path_to(*names[1..-1], **params)
          return path
        end
      end

      nil
    end
  end
end
