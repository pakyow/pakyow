require 'support/helper'

describe 'Application' do
  include ApplicationTestHelpers

  it 'path is set when inherited' do
    expect(Pakyow::Config.app.path.include?(app_test_path)).to eq true
  end

  it 'runs' do
    app(true).run(:test)
    expect(app.running?).to eq true
  end

  it 'is staged when running' do
    app(true).run(:test)
    expect(app.staged?).to eq true
  end

  it 'does not run when staged' do
    app(true).stage(:test)
    expect(app.running?).to eq false
  end

  it 'when staged can be detected' do
    app(true).stage(:test)
    expect(app.staged?).to eq true
  end

  it 'base config can be accessed' do
    expect(app(true).config).to eq Pakyow::Config
  end

  it 'env is set when initialized' do
    envs = [:test, :foo]
    app(true).stage(*envs)
    expect(Pakyow::Config.env).to eq envs.first
  end

  it 'app helper is set when initialized' do
    app(true)
    expect(Pakyow.app).to be_nil
    app(true).run(:test)
    expect(Pakyow.app.class).to eq Pakyow::App
  end

  it 'global configuration block is executed' do
    expect($global_config_was_executed).to eq true
  end

  it 'loads global configuration first' do
    expect($env_overwrites_global_config).to eq true
  end

  it 'configuration loaded before middleware' do
    app = app(true)

    value = nil
    app.middleware do
      value = config.app.foo
    end

    app.stage(:test)

    expect(value).to eq :bar
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

    expect(value1).to eq :bar
    expect(value2).to eq :bar
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
