module AppHelpers
  def setup(env: :test)
    Pakyow.mount app, at: "/", &app_runtime_block
    Pakyow.setup(env: env)
  end

  def run
    @app = Pakyow.run
  end

  def call(path = "/", opts = {})
    @app.call(Rack::MockRequest.env_for(path, opts))
  end

  def app_definition
    Proc.new do; end
  end
end
