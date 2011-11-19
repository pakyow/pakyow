module Pakyow
  class Reloader
    def initialize(app)
      @app = app
    end
    
    def call(env)
      @app.reload
      @app.call(env)
    end
  end
end
