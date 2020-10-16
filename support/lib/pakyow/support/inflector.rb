# frozen_string_literal: true

module Pakyow
  module Support
    def self.inflector
      unless defined?(@__inflector)
        require "dry/inflector"
        @__inflector = Dry::Inflector.new { |inflections|
          inflections.uncountable "children"
        }
      end

      @__inflector
    end
  end
end
