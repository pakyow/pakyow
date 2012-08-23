module Pakyow
  module Middleware
    class Presenter
      def initialize(app)
        @app = app
      end

      def call(env)
        request = Request.new(env)

        #TODO dry up with application (move to Request#new?)
        base_route, ignore_format = StringUtils.split_at_last_dot(request.path)
        request.working_path = base_route
        request.working_method = request.method
        
        Pakyow.app.presenter.prepare_for_request(request)        
        @app.call(env)

        content = Pakyow.app.presenter.content

        #TODO handle this with catch (like in logger)
        if Pakyow.app.response.status == 404
          Pakyow.app.presenter.prepare_for_request(Pakyow.app.request)
          content = Pakyow.app.presenter.content
        end

        Pakyow.app.response.body = [content]
        Pakyow.app.response.finish
      end
    end
  end
end
