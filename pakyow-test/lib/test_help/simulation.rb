require 'forwardable'

module Pakyow
  module TestHelp
    class Simulation
      extend Forwardable

      REDIRECT_STATUSES = [301, 302, 307]

      attr_reader :app
      def_delegators :app, :request, :response, :req, :res
      def_delegators :response, :status, :type, :format

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

      private

      def router
        Pakyow::Router.instance
      end
    end
  end
end
