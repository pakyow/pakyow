RSpec.shared_context "testable app" do
  let :app do
    Pakyow::App
  end

  let :app_runtime_block do
    Proc.new {}
  end

  let :autorun do
    true
  end

  before do
    Pakyow.config.server.default = :mock

    if app_definition
      app.define(&app_definition)
      run if autorun
    end
  end

  after do
    Pakyow.reset
    app.reset
  end
end

module Pakyow::Support::Definable
  def deep_freeze
    # noop; we don't want to freeze in our own specs because we want we want each group of tests
    # to register new state; this can't happen if definables are frozen
  end
end
