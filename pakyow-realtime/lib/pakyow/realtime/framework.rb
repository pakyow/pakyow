# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/app/helpers/realtime/broadcasting"
require "pakyow/app/helpers/realtime/subscriptions"
require "pakyow/app/helpers/realtime/socket"

require "pakyow/app/config/realtime"
require "pakyow/app/behavior/realtime/serialization"
require "pakyow/app/behavior/realtime/server"
require "pakyow/app/behavior/realtime/silencing"

require "pakyow/presenter/renderer/behavior/realtime/install_websocket"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        object.class_eval do
          register_helper :active, App::Helpers::Realtime::Broadcasting
          register_helper :active, App::Helpers::Realtime::Subscriptions
          register_helper :passive, App::Helpers::Realtime::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          include App::Config::Realtime
          include App::Behavior::Realtime::Server
          include App::Behavior::Realtime::Silencing
          include App::Behavior::Realtime::Serialization

          isolated :Renderer do
            include Presenter::Renderer::Behavior::Realtime::InstallWebsocket
          end

          isolated :Connection do
            after "initialize" do
              set(:__socket_client_id, params[:socket_client_id] || Support::MessageVerifier.key)
            end
          end
        end
      end
    end
  end
end
