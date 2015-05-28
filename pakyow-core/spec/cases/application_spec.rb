require 'support/helper'

describe 'Application' do
  include ApplicationTestHelpers

  it 'path is set when inherited' do
    expect(Pakyow::Config.app.path.include?(app_test_path)).to eq true
  end

  it 'runs' do
    app(true).run(:test)
    expect(true).to eq app.running?
  end

  it 'is staged when running' do
    app(true).run(:test)
    expect(true).to eq app.staged?
  end

  it 'does not run when staged' do
    app(true).stage(:test)
    expect(false).to eq app.running?
  end

  it 'when staged can be detected' do
    app(true).stage(:test)
    expect(true).to eq app.staged?
  end

  it 'base config can be accessed' do
    expect(Pakyow::Config).to eq app(true).config
  end

  it 'env is set when initialized' do
    envs = [:test, :foo]
    app(true).stage(*envs)
    expect(envs.first).to eq Pakyow.app.env
  end

  it 'app helper is set when initialized' do
    app(true)
    expect(Pakyow.app).to be_nil
    app(true).run(:test)
    expect(Pakyow::App).to eq Pakyow.app.class
  end

  it 'global configuration block is executed' do
    expect(true).to eq $global_config_was_executed
  end

  it 'global configuration supercedes env' do
    expect(false).to eq $env_overwrites_global_config
  end

  it 'configuration loaded before middleware' do
    app = app(true)

    value = nil
    app.middleware do
      value = config.app.foo
    end

    app.stage(:test)

    expect(:bar).to eq value
  end

  it 'can load multiple multiple middleware' do
    app = app(true)

    value1 = nil
    app.middleware do
      value1 = config.app.foo
    end

    value2 = nil
    app.middleware do
      value2 = config.app.foo
    end

    app.stage(:test)

    expect(:bar).to eq value1
    expect(:bar).to eq value2
  end

  it 'builder is yielded to middleware' do
    app = app(true)

    builder = nil
    app.middleware do |o|
      builder = o
    end

    app.stage(:test)

    expect(builder).to be_a Rack::Builder
  end
end
