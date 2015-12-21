module Pakyow
  module Middleware
    # Rack compatible middleware that tells app to reload on each request.
    #
    # @api public
    class Reloader
      def initialize(app)
        @app = app
      end

      def call(env)
        Pakyow.app.reload
        @app.call(env)
      end
    end
  end
end
