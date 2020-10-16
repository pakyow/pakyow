# frozen_string_literal: true

require "delegate"

module Pakyow
  module Data
    class Result < SimpleDelegator
      # @api private
      attr_reader :__proxy

      def initialize(result, proxy, originating_method: nil, originating_args: [])
        @__proxy = proxy
        @originating_method = originating_method
        @originating_args = originating_args
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
          },

          originating_method: @originating_method,
          originating_args: @originating_args
        }
      end

      def marshal_load(state)
        result = state[:proxy][:app].data.public_send(
          state[:proxy][:source]
        ).apply(
          state[:proxy][:proxied_calls]
        )

        if state[:originating_method]
          result = result.public_send(state[:originating_method], *state[:originating_args])
        end

        __setobj__(result)
      end

      # Fixes an issue using pp inside a delegator.
      #
      def pp(*args)
        Kernel.pp(*args)
      end
    end
  end
end
