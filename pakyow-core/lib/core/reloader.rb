module Pakyow
  class Reloader
    def initialize(app)
      @app = app
    end
    
    def call(env)
      @app.load_app
      @app.call(env)
    end
  end
end
