module Pakyow
  module Middleware
    class Router
      def initialize(app)
        @app = app
      end

      def call(env)
        catch(:halt) {
          Pakyow.app.router.route!(Pakyow.app.request)
          @app.call(env)
        }
      rescue StandardError => error
        Pakyow.app.request.error = error

        Pakyow.app.response.status = 500
        Pakyow.app.router.handle!(500)

        if Configuration::Base.app.errors_in_browser
          Pakyow.app.response["Content-Type"] = 'text/html'
          Pakyow.app.response.body = []
          Pakyow.app.response.body << "<h4>#{CGI.escapeHTML(error.to_s)}</h4>"
          Pakyow.app.response.body << error.backtrace.join("<br />")
        else
          if Pakyow.app.presenter
            # consider moving to presenter middleware
            # Pakyow.app.presenter.prepare_for_request(Pakyow.app.request)
            Pakyow.app.response.body = [Pakyow.app.presenter.content] if Pakyow.app.presenter.presented?
          end
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
