module Pakyow
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        Pakyow.app.router.route!(Pakyow.app.request)
        @app.call(env)
      rescue StandardError => error
        Pakyow.app.request.error = error
        Pakyow.app.router.handle!(500)
        Pakyow.app.response.status = 500

        if Configuration::Base.app.errors_in_browser
          Pakyow.app.response.body = []
          Pakyow.app.response.body << "<h4>#{CGI.escapeHTML(error.to_s)}</h4>"
          Pakyow.app.response.body << error.backtrace.join("<br />")
        end

        begin
          # caught by other middleware (e.g. logger)
          throw :error, error
        rescue ArgumentError
        end
      end
    end
  end
end
