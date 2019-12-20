# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/application/helpers/realtime/broadcasting"
require "pakyow/application/helpers/realtime/subscriptions"
require "pakyow/application/helpers/realtime/socket"

require "pakyow/application/config/realtime"
require "pakyow/application/behavior/realtime/handling"
require "pakyow/application/behavior/realtime/serialization"
require "pakyow/application/behavior/realtime/server"
require "pakyow/application/behavior/realtime/silencing"

require "pakyow/presenter/renderer/behavior/realtime/install_websocket"

require "pakyow/application/actions/realtime/upgrader"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        object.class_eval do
          register_helper :active, Application::Helpers::Realtime::Broadcasting
          register_helper :active, Application::Helpers::Realtime::Subscriptions
          register_helper :passive, Application::Helpers::Realtime::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          include Application::Config::Realtime
          include Application::Behavior::Realtime::Server
          include Application::Behavior::Realtime::Handling
          include Application::Behavior::Realtime::Silencing
          include Application::Behavior::Realtime::Serialization

          isolated :Renderer do
            include Presenter::Renderer::Behavior::Realtime::InstallWebsocket
          end

          isolated :Connection do
            after "initialize" do
              set(:__socket_client_id, params[:socket_client_id] || Support::MessageVerifier.key)
            end
          end

          after "load" do
            if Pakyow.config.realtime.server && !is_a?(Plugin)
              action(Application::Actions::Realtime::Upgrader)
            end
          end
        end
      end
    end
  end
end
