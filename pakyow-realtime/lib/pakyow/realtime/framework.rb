# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/realtime/helpers/broadcasting"
require "pakyow/realtime/helpers/subscriptions"
require "pakyow/realtime/helpers/socket"

require "pakyow/realtime/behavior/config"
require "pakyow/realtime/behavior/building"
require "pakyow/realtime/behavior/rendering"
require "pakyow/realtime/behavior/serialization"
require "pakyow/realtime/behavior/server"
require "pakyow/realtime/behavior/silencing"

require "pakyow/realtime/actions/upgrader"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        object.class_eval do
          register_helper :active, Helpers::Broadcasting
          register_helper :active, Helpers::Subscriptions
          register_helper :passive, Helpers::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          include Behavior::Config
          include Behavior::Building
          include Behavior::Server
          include Behavior::Silencing
          include Behavior::Serialization

          isolated :ViewRenderer do
            include Behavior::Rendering
          end

          isolated :Connection do
            after :initialize do
              set(:__socket_client_id, params[:socket_client_id] || Support::MessageVerifier.key)
            end
          end
        end
      end
    end
  end
end
