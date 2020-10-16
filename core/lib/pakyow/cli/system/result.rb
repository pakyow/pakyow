# frozen_string_literal: true

require "forwardable"

module Pakyow
  class CLI
    module System
      class Result
        extend Forwardable
        def_delegators :@__result, :complete?, :success?, :failure?

        def initialize(tty_result)
          @__result = tty_result
        end
      end
    end
  end
end
