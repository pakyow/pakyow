# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        require_relative "../application/actions/realtime/upgrader"

        require_relative "../application/helpers/realtime/broadcasting"
        require_relative "../application/helpers/realtime/subscriptions"
        require_relative "../application/helpers/realtime/socket"

        require_relative "../application/behavior/realtime/handling"
        require_relative "../application/behavior/realtime/silencing"

        require_relative "../presenter/renderer/behavior/realtime/install_websocket"

        object.class_eval do
          register_helper :active, Application::Helpers::Realtime::Broadcasting
          register_helper :active, Application::Helpers::Realtime::Subscriptions
          register_helper :passive, Application::Helpers::Realtime::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          configurable :realtime do
            setting :path, "pw-socket"
            setting :endpoint
            setting :log_initial_request, false

            defaults :production do
              setting :log_initial_request, true
            end
          end

          include Application::Behavior::Realtime::Handling
          include Application::Behavior::Realtime::Silencing

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
