# frozen_string_literal: true

module Pakyow
  module Support
    def self.inflector
      unless defined?(@__inflector)
        require "dry/inflector"
        @__inflector = Dry::Inflector.new do |inflections|
          inflections.uncountable "children"
        end
      end

      @__inflector
    end
  end
end
