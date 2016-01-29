module Pakyow
  module Middleware
    Pakyow::App.middleware do |builder|
      if Pakyow::Config.reloader.enabled
        builder.use Pakyow::Middleware::Reloader
      end
    end

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
