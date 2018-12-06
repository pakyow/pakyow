# frozen_string_literal: true

require "dry/inflector"

module Pakyow
  module Support
    def self.inflector
      @inflector ||= Dry::Inflector.new do |inflections|
        inflections.uncountable "children"
      end
    end
  end
end
