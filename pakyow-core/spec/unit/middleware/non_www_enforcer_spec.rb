require 'spec_helper'
require 'pakyow/core/middleware/non_www_enforcer'

RSpec.describe Pakyow::Middleware::NonWWWEnforcer do
  let :app do
    double
  end

  let :instance do
    Pakyow::Middleware::NonWWWEnforcer.new(app)
  end

  let :env do
    {
      'SERVER_NAME' => host,
      'REQUEST_METHOD' => method
    }
  end

  let :host do
    'pakyow.com'
  end

  let :host_www do
    'www.pakyow.com'
  end

  let :host_subdomain do
    'foo.pakyow.com'
  end

  let :method do
    'GET'
  end

  before do
    allow(app).to receive(:enforce_www)
    allow(Pakyow).to receive(:app).and_return(app)
    allow(app).to receive(:call)

    # @original_builder = Pakyow::App.builder
    # Pakyow::App.instance_variable_set(:@builder, double(Rack::Builder).as_null_object)
  end

  after do
    # Pakyow::App.instance_variable_set(:@builder, @original_builder)
  end

  # TODO: move to test pakyow/core/hooks (integration test)
  # describe 'www is enforced' do
  #   before { allow(app).to receive(:enforce_www) { true } }

  #   it 'does not use the non_www_enforcer middleware' do
  #     expect(Pakyow::App.builder).not_to receive(:use).with(Pakyow::Middleware::NonWWWEnforcer)
  #   end
  # end

  describe '#call' do
    it 'exists' do
      expect(instance).to respond_to(:call)
    end

    it 'accepts one arg' do
      expect(instance.method(:call).arity).to eq(1)
    end

    context 'www is not enforced and host have www' do
      before do
        allow(app).to receive(:enforce_www) { false }
        env['SERVER_NAME'] = host_www
      end

      it 'issues a 301 redirect and add www to host name' do
        expect_any_instance_of(Pakyow::CallContext).to receive(:redirect).with(host, 301)
        instance.call(env)
      end
    end

    context 'www is not enforced and host doesn\'t have www' do
      before do
        allow(app).to receive(:enforce_www) { false }
      end

      it 'pass the request through' do
        expect(app).to receive(:call)
        instance.call(env)
      end
    end
  end

  describe '#www?' do
    it 'return true if host starts with www' do
      expect(instance.www?(host_www)).to eq(true)
    end

    it 'return false if host doesn\'t start with www' do
      expect(instance.www?([host, host_subdomain].sample)).to eq(false)
    end
  end

  describe '#remove_www' do
    it 'removes "www." from host name' do
      expect(instance.remove_www(host_www)).to eq(host)
    end
  end
end
