require 'support/helper'

describe 'Application' do
  include ApplicationTestHelpers

  it 'path is set when inherited' do
    expect(Pakyow::Config.app.path.include?(app_test_path)).to eq true
  end

  it 'is staged when running' do
    expect(app).to receive(:stage).with(:test)
    app.run(:test)
  end

  it 'does not run when staged' do
    expect(app).not_to receive(:run)
    app.stage(:test)
  end

  it 'base config can be accessed' do
    expect(app.config).to eq Pakyow::Config
  end

  it 'env is set when initialized' do
    env = :test
    app.stage(env)
    expect(Pakyow::Config.env).to eq env
  end

  it 'app helper is set when initialized' do
    Pakyow.app = nil
    app.run(:test)
    expect(Pakyow.app.class).to eq Pakyow::App
  end

  it 'global configuration block is executed' do
    app.run(:test)
    expect($global_config_was_executed).to eq true
  end

  it 'loads global configuration first' do
    app.run(:test)
    expect($env_overwrites_global_config).to eq true
  end

  it 'configuration loaded before middleware' do
    value = nil
    app.middleware do
      value = config.app.foo
    end

    app.stage(:test)

    expect(value).to eq :bar
  end

  it 'can load multiple multiple middleware' do
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
    builder = nil
    app.middleware do |o|
      builder = o
    end

    app.stage(:test)

    expect(builder).to be_a Rack::Builder
  end
end
