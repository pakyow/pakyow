module Pakyow
  module Middleware
    class NotFound
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
        
        # 404 if no route matched and no views were found
        if (!Pakyow.app.routed? && !Configuration::App.all_views_visible) || (!Pakyow.app.presenter || !Pakyow.app.presenter.presented?)
          Log.enter "[404] Not Found"

          Pakyow.app.response.status = 404
          Pakyow.app.invoke_handler!(404)

          if Pakyow.app.presenter
            # consider moving to presenter middleware
            # Pakyow.app.presenter.prepare_for_request(Pakyow.app.request)
            Pakyow.app.response.body = [Pakyow.app.presenter.content] if Pakyow.app.presenter.presented?
          end
        end
      end
    end
  end
end
