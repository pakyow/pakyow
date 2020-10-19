RSpec.shared_context "app" do
  let :app do
    local_app_def = app_def

    block = if defined?(@default_app_def)
      local_default_app_def = @default_app_def

      Proc.new do
        class_exec(&local_default_app_def)
        class_exec(&local_app_def)
      end
    else
      Proc.new do
        class_exec(&local_app_def)
      end
    end

    Pakyow.app(:test, mount: false, without: excluded_frameworks, &block)
  end

  let :excluded_frameworks do
    if defined?(@excluded_frameworks)
      @excluded_frameworks
    else
      []
    end
  end

  let :env_def do
    Proc.new {}
  end

  let :app_def do
    Proc.new {}
  end

  let :autorun do
    true
  end

  let :mode do
    :test
  end

  let :mount_path do
    "/"
  end

  let :connection do
    @connection
  end

  let :mount_app do
    true
  end

  before do
    ENV["SECRET"] = "test"
    Pakyow.config.logger.enabled = false
    Pakyow.instance_variable_set(:@error, nil)
    setup_and_run if autorun
  end

  def setup(env: :test)
    super if defined?(super)

    if mount_app
      Pakyow.mount(app, at: mount_path)
    else
      app
    end

    Pakyow.class_eval(&env_def)
    Pakyow.setup(env: env)
  end

  def run
    Pakyow.boot
    check_environment
    check_apps
  end

  def setup_and_run(env: mode)
    setup(env: env) && run
  end

  unless defined?(DEFAULT_HEADERS)
    DEFAULT_HEADERS = { "content-type" => "text/html" }.freeze
  end

  def call(path = "/", headers: {}, method: :get, tuple: true, input: nil, params: nil, scheme: "http")
    connection_for_call = nil
    allow_any_instance_of(Pakyow::Connection).to receive(:finalize).and_wrap_original do |original_method|
      connection_for_call = original_method.receiver
      original_method.call
    end

    if params
      input = StringIO.new(params.to_json)
      headers["content-type"] = "application/json"
    end

    DEFAULT_HEADERS.each do |key, value|
      unless headers.include?(key)
        headers[key] = value
      end
    end

    body = Async::HTTP::Body::Buffered.wrap(input)
    request = Async::HTTP::Protocol::Request.new(scheme, "localhost", method.to_s.upcase, path, nil, Protocol::HTTP::Headers[headers], body)
    request.remote_address = Addrinfo.tcp("localhost", "http")

    Async::Reactor.run {
      result = Pakyow.call(request).tap do
        @connection = connection_for_call
        check_response(connection_for_call)
      end

      if tuple
        response_body = String.new
        while content = result.body.read
          response_body << content
        end

        [result.status, result.headers.to_h, response_body]
      else
        result
      end
    }.wait
  end

  def call_fast(path = "/", opts = {})
    # TODO: this'll need to be updated
    @app.call(Rack::MockRequest.env_for(path, opts))
  end

  let :allow_environment_errors do
    false
  end

  let :allow_application_rescues do
    false
  end

  let :allow_request_failures do
    false
  end

  def check_environment
    if Pakyow.error && !allow_environment_errors
      fail <<~MESSAGE
        Environment unexpectedly failed to boot:

          #{Pakyow.error.class}: #{Pakyow.error.message}

        #{Pakyow.error.backtrace.to_a.join("\n")}
      MESSAGE
    end
  end

  def check_apps
    Pakyow.apps.each do |app|
      if app.respond_to?(:rescued?) && app.rescued? && !allow_application_rescues
        fail <<~MESSAGE
          #{app.class} unexpectedly failed to boot:

            #{app.rescued.class}: #{app.rescued.message}

          #{app.rescued.backtrace.to_a.join("\n")}
        MESSAGE
      end
    end
  end

  def check_response(connection)
    if connection && connection.status.to_i >= 500 && !allow_application_rescues && !allow_request_failures
      fail <<~MESSAGE
        Request unexpectedly failed.

          #{connection.error.class}: #{connection.error.message}

        #{connection.error.backtrace.to_a.join("\n")}
      MESSAGE
    end
  end
end
