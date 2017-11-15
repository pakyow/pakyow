require "pakyow/data/model"

module Pakyow
  module Data
    # Wraps a relation to keep track of what query it originated from.
    #
    class Query < Model
      def initialize(relation, name, args)
        super(relation)
        @name, @args = name, args
      end

      # TODO: support passing a mapper through an `as` method that uses map_to behind the scenes
    end
  end
end
