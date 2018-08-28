# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/realtime/helpers/broadcasting"
require "pakyow/realtime/helpers/subscriptions"
require "pakyow/realtime/helpers/socket"

require "pakyow/realtime/behavior/config"
require "pakyow/realtime/behavior/rendering"
require "pakyow/realtime/behavior/server"
require "pakyow/realtime/behavior/silencing"

require "pakyow/realtime/actions/upgrader"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        app.class_eval do
          action Actions::Upgrader
          helper Helpers::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          include Behavior::Config
          include Behavior::Rendering
          include Behavior::Server
          include Behavior::Silencing

          isolated :Controller do
            include Helpers::Broadcasting
            include Helpers::Subscriptions
          end
        end
      end
    end
  end
end
