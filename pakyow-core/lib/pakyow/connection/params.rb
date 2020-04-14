# frozen_string_literal: true

require "delegate"
require "forwardable"

require "pakyow/support/indifferentize"

require_relative "query_parser"

module Pakyow
  class Connection
    class Params < DelegateClass(Support::IndifferentHash)
      extend Forwardable
      def_delegators :@parser, :parse, :add, :add_value_for_key

      def initialize
        params = Support::IndifferentHash.new
        @parser = QueryParser.new(params: params)
        super(params)
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end
    end
  end
end
