# frozen_string_literal: true

module Pakyow
  module Data
    module Validations
      module Presence
        def self.name
          :presence
        end

        def self.valid?(value, **)
          !value.nil? && !value.empty?
        end
      end

      Validator.register_validation(Presence)
    end
  end
end
