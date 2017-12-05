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
    Pakyow.config.server.default = :mock

    if autorun
      run(env: respond_to?(:mode) ? mode : :test)
    end
  end
end
