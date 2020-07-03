# frozen_string_literal: true

require "forwardable"

module Pakyow
  module Support
    module ThreadLocalizer
      class Store
        extend Forwardable
        def_delegators :@state, :[], :[]=, :fetch, :delete

        def initialize
          @state = {}
        end
      end
    end
  end
end
