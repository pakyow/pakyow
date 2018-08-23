# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module UI
    module Behavior
      module Timeouts
        extend Support::Extension

        # How long we want to wait before cleaning up data subscriptions. We set the subscriber
        # (the WebSocket connection) to expire when it's initially created. This way if it never
        # connects the subscription will be cleaned up, preventing orphaned subscriptions. We
        # schedule an expiration on disconnect for the same reason.
        #
        # When the WebSocket connects, we persist the subscriber, cancelling the expiration.
        #
        SUBSCRIPTION_TIMEOUT = 60

        apply_extension do
          on :join do
            @connection.app.data.persist(@id)
          end

          on :leave do
            @connection.app.data.expire(@id, SUBSCRIPTION_TIMEOUT)
          end

          subclass :ViewRenderer do
            after :render do
              # Set the subscriptions we just created to expire if the connection is never established.
              #
              @connection.app.data.expire(socket_client_id, SUBSCRIPTION_TIMEOUT)
            end
          end
        end
      end
    end
  end
end
