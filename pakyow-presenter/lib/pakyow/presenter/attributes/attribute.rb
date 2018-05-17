# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Presenter
    module Attributes
      # @api private
      class Attribute
        using Support::DeepDup

        def initialize(value)
          @value = value
        end

        def deep_dup
          self.class.new(@value.deep_dup)
        end

        def ==(other)
          @value == other
        end
      end
    end
  end
end
