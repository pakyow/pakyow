RSpec.shared_context "app" do
  let :app do
    local_app_def = app_def

    block = if instance_variable_defined?(:@default_app_def)
      local_default_app_def = @default_app_def

      Proc.new do
        instance_exec(&local_default_app_def)
        instance_exec(&local_app_def)
      end
    else
      Proc.new do
        instance_exec(&local_app_def)
      end
    end

    Pakyow.app(:test, &block)
  end

  let :app_def do
    Proc.new {}
  end

  let :app_init do
    Proc.new {}
  end

  let :autorun do
    true
  end

  let :mode do
    :test
  end

  before do
    Pakyow.config.server.name = :mock
    Pakyow.config.logger.enabled = false
    setup_and_run if autorun
  end

  def setup(env: :test)
    super if defined?(super)
    Pakyow.mount app, at: "/", &app_init
    Pakyow.setup(env: env)
  end

  def run
    @app = Pakyow.run
  end

  def setup_and_run(env: mode)
    setup(env: env) && run
  end

  def call(path = "/", opts = {})
    @app.call(Rack::MockRequest.env_for(path, opts))
  end
end
