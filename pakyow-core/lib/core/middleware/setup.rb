module Pakyow
  module Middleware
    class Setup
      def initialize(app)
        @app = app
      end

      def call(env)
        #TODO don't track r/r on app; pass through middleware instead (or call in a context that has access to current r/r)
        Pakyow.app.setup_rr(env)
        @app.call(env)
      end
    end
  end
end
