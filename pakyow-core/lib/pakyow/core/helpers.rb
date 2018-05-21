# frozen_string_literal: true

require "pakyow/support/message_verifier"
require "pakyow/support/safe_string"

module Pakyow
  module Routing
    module Helpers
      include Support::SafeStringHelpers

      # Expose a value by name, if the value is not already set.
      #
      def expose(name, default_value = default_omitted = true, &block)
        unless @connection.set?(name)
          set_exposure(name, default_value, default_omitted, &block)
        end
      end

      # Force expose a value by name, overriding any existing value.
      #
      def expose!(name, default_value = default_omitted = true, &block)
        set_exposure(name, default_value, default_omitted, &block)
      end

      # @api private
      def set_exposure(name, default_value, default_omitted)
        value = if block_given?
          yield
        elsif default_omitted
          __send__(name)
        end

        unless default_omitted
          value ||= default_value
        end

        @connection.set(name, value)
      end

      module CSRF
        def authenticity_server_id
          return @connection.params[:authenticity_server_id] if @connection.params[:authenticity_server_id]
          @connection.session[:authenticity_server_id] ||= Support::MessageVerifier.key
        end

        def authenticity_client_id
          return @connection.params[:authenticity_client_id] if @connection.params[:authenticity_client_id]
          @authenticity_client_id ||= Support::MessageVerifier.key
        end

        def authenticity_digest(authenticity_client_id)
          Support::MessageVerifier.digest(authenticity_client_id, key: authenticity_server_id)
        end
      end
    end
  end
end
