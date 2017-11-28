# frozen_string_literal: true

module Pakyow
  class Router
    def_delegators :controller, :data, :verify

    class << self
      # Perform input verification before one or more routes, identified by name.
      #
      # @see Pakyow::Data::Verifier
      #
      # @api public
      def verify(*names, &block)
        before(*names) do
          verify(&block)
        end
      end
    end
  end
end
