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
                                                                  #TODO the right thing to do?
        Pakyow.app.response.body = [Pakyow.app.presenter.content] if Pakyow.app.presenter.presented?
        Pakyow.app.response.finish
      end
    end
  end
end
