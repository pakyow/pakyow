# frozen_string_literal: true

require "pakyow/framework"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        require "pakyow/application/actions/realtime/upgrader"

        require "pakyow/application/helpers/realtime/broadcasting"
        require "pakyow/application/helpers/realtime/subscriptions"
        require "pakyow/application/helpers/realtime/socket"

        require "pakyow/application/behavior/realtime/handling"
        require "pakyow/application/behavior/realtime/serialization"
        require "pakyow/application/behavior/realtime/server"
        require "pakyow/application/behavior/realtime/silencing"

        require "pakyow/presenter/renderer/behavior/realtime/install_websocket"

        require "pakyow/application/actions/realtime/upgrader"

        object.class_eval do
          register_helper :active, Application::Helpers::Realtime::Broadcasting
          register_helper :active, Application::Helpers::Realtime::Subscriptions
          register_helper :passive, Application::Helpers::Realtime::Socket

          # Socket events are triggered on the app.
          #
          events :join, :leave

          configurable :realtime do
            setting :adapter_settings, {}
            setting :path, "pw-socket"
            setting :endpoint
            setting :log_initial_request, false

            defaults :production do
              setting :adapter_settings do
                { key_prefix: [Pakyow.config.redis.key_prefix, config.name].join("/") }
              end

              setting :log_initial_request, true
            end

            configurable :timeouts do
              # Give sockets 60 seconds to connect before cleaning up their state.
              #
              setting :initial, 60

              # When a socket disconnects, keep state around for 24 hours before
              # cleaning up. This improves the user experience in cases such as
              # when a browser window is left open on a sleeping computer.
              #
              setting :disconnect, 24 * 60 * 60
            end
          end

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
