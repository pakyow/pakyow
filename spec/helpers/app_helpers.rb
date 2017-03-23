module AppHelpers
  def run(env: :test)
    Pakyow.mount app, at: "/", &app_runtime_block
    @app = Pakyow.setup(env: env).run
  end

  def call(path = "/", opts = {})
    @app.call(Rack::MockRequest.env_for(path, opts))
  end
end
