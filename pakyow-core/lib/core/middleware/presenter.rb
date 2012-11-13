module Pakyow
  module Middleware
    class Presenter
      def initialize(app)
        @app = app
      end

      def call(env)
        r = Pakyow.app.request

        while(r) do
          Pakyow.app.presenter.prepare_for_request(Pakyow.app.request)

          r = catch(:rerouted) {
                   @app.call(@env)
                   nil
                 }
        end
                                                                  #TODO the right thing to do?
        Pakyow.app.response.body = [Pakyow.app.presenter.content] if Pakyow.app.presenter.presented?
        Pakyow.app.response.finish
      end
    end
  end
end
