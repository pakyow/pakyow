# frozen_string_literal: true

require "dry/inflector"

module Pakyow
  module Support
    def self.inflector
      @inflector ||= Dry::Inflector.new
    end
  end
end
