module Pakyow
  module Middleware
    class Presenter
      def initialize(app)
        @app = app
      end

      def call(env)
        Pakyow.app.presenter.prepare_for_request(Pakyow.app.request)

        if r = catch(:rerouted) {
                 @app.call(env)
                 nil
               }

          Pakyow.app.presenter.prepare_for_request(r)
        end


        Pakyow.app.response.body = [Pakyow.app.presenter.content]
        Pakyow.app.response.finish
      end
    end
  end
end
