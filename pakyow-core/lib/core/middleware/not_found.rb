module Pakyow
  module Middleware
    class NotFound
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
        
        # 404 if no route matched and no views were found
        if !Pakyow.app.routed? && (!Pakyow.app.presenter || !Pakyow.app.presenter.presented?)
          Log.enter "[404] Not Found"
          Pakyow.app.handle_404

          if Pakyow.app.presenter
            # consider moving to presenter middleware
            Pakyow.app.presenter.prepare_for_request(Pakyow.app.request)
            Pakyow.app.response.body = [Pakyow.app.presenter.content]
          end
        end

        Pakyow.app.response.finish
      end
    end
  end
end
