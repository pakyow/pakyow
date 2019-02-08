# frozen_string_literal: true

require "delegate"

module Pakyow
  module Data
    class Result < SimpleDelegator
      def initialize(result, proxy)
        @__proxy = proxy
        __setobj__(result)
      end

      def nil?
        __getobj__.nil?
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end
    end
  end
end
