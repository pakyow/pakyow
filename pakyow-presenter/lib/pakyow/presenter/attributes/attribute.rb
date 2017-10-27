require "delegate"

require "pakyow/support/deep_dup"

module Pakyow
  module Presenter
    module Attributes
      # @api private
      class Attribute < SimpleDelegator
        using Support::DeepDup

        def initialize(value)
          super value
        end

        def deep_dup
          __getobj__.deep_dup
        end
      end
    end
  end
end
