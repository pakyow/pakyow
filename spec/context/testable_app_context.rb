RSpec.shared_context "testable app" do
  let :app do
    Pakyow.app(:test, &app_definition)
  end

  let :app_runtime_block do
    Proc.new { }
  end

  let :autorun do
    true
  end

  before do
    Pakyow.config.server.name = :mock
    Pakyow.config.logger.enabled = false
    run_app if autorun
  end

  def run_app(env: respond_to?(:mode) ? mode : :test)
    setup(env: env) && run
  end

  def setup(env: :test)
    super if defined?(super)
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
