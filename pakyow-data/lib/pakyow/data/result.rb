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

      def marshal_dump
        {
          proxy: {
            app: @__proxy.app,
            source: @__proxy.source.source_name,
            proxied_calls: @__proxy.proxied_calls
          }
        }
      end

      def marshal_load(state)
        __setobj__(
          state[:proxy][:app].data.public_send(
            state[:proxy][:source]
          ).apply(state[:proxy][:proxied_calls])
        )
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end
    end
  end
end
