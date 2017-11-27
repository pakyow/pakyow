# frozen_string_literal: true

module Pakyow
  module Data
    module Validations
      module Presence
        Validator.register_validation :presence, self

        def self.valid?(value)
          !value.nil? && !value.empty?
        end
      end
    end
  end
end
