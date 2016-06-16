require 'spec_helper'
require 'pakyow/core/middleware/www_enforcer'

describe Pakyow::Middleware::WWWEnforcer do
  let :app do
    double
  end

  let :instance do
    Pakyow::Middleware::WWWEnforcer.new(app)
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
    allow(app).to receive(:enforce_www) { true }
    allow(Pakyow).to receive(:app).and_return(app)
    allow(app).to receive(:call)
  end

  describe 'when enforce_www is false' do
    before { allow(app).to receive(:enforce_www) { false } }

   it 'does not use the www_enforcer middleware' do
      expect(Pakyow::App.builder).not_to receive(:use).with(Pakyow::Middleware::WWWEnforcer)
    end
  end

  describe '#call' do
    it 'exists' do
      expect(instance).to respond_to(:call)
    end

    it 'accepts one arg' do
      expect(instance.method(:call).arity).to eq(1)
    end

    context 'www is enforced and host doesn\'t have www' do
      before { env['SERVER_NAME'] = host }

      it 'issues a 301 redirect and add "www." to host name' do
        expect_any_instance_of(Pakyow::CallContext).to receive(:redirect).with(host_www, 301)
        instance.call(env)
      end
    end

    context 'www is enforced and host have www or is a subdomain' do
      before { env['SERVER_NAME'] = [host_www, host_subdomain].sample }

      it 'pass the request through' do
        expect(app).to receive(:call)
        instance.call(env)
      end
    end
  end

  describe '#subdomain?' do
    it 'return true if host is a subdomain' do
      expect(instance.subdomain?(host_subdomain)).to eq(true)
    end

    it 'return false if host is not a subdomain' do
      expect(instance.subdomain?(host)).to eq(false)
    end
  end

  describe '#add_www' do
    it 'removes "www." from host name' do
      expect(instance.add_www(host)).to eq(host_www)
    end
  end
end
