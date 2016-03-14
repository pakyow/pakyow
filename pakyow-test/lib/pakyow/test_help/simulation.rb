require 'forwardable'

module Pakyow
  module TestHelp
    class Simulation
      extend Forwardable

      REDIRECT_STATUSES = [301, 302, 307]

      attr_reader :app
      def_delegators :app, :request, :response, :req, :res, :presenter, :socket, :socket_digest, :socket_connection_id
      def_delegators :response, :status, :type, :format
      def_delegators :presenter, :view

      def initialize(app)
        @app = app
      end

      def redirected?(to: nil, as: nil)
        return false unless REDIRECT_STATUSES.include?(response.status)
        return false unless response.headers.key?('Location')

        unless to.nil?
          path = router.path(to)
          return false if response.headers['Location'] != path
        end

        unless as.nil?
          return status == as
        end

        return true
      end

      def rerouted?(to: nil)
        return false if request.first_path == request.path

        unless to.nil?
          return request.path == router.path(to)
        end

        return true
      end

      def subscribed?(to: nil)
        if to.nil?
          !channels.empty?
        else
          channels.include?(to.to_sym)
        end
      end

      def unsubscribed?(to: nil)
        !subscribed?(to: to)
      end

      def pushed?(message = nil, to: nil)
        socket.pushed?(message, to: to)
      end

      def log
        app.request.env['rack.logger']
      end

      private

      def router
        Pakyow::Router.instance
      end

      def channels
        socket.delegate.registry.channels_for_key(socket_digest(socket_connection_id))
      end
    end
  end
end
