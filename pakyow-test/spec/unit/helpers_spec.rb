require_relative 'support/unit_helper'
require_relative '../../lib/test_help/helpers'

class HelperIncluder
  include Pakyow::TestHelp::Helpers
end

describe Pakyow::TestHelp::Helpers do
  let :instance do
    HelperIncluder.new
  end

  let :simulation do
    instance_double('Simulation')
  end

  describe 'simulate' do
    let :name do
      '/'
    end

    let :method do
      :get
    end

    let :with do
      { foo: 'bar' }
    end

    let :session do
      { user: 1 }
    end

    let :cookies do
      { user: 2 }
    end

    let :env do
      { bar: 'foo' }
    end

    it 'creates and runs the simulator with name, method, params, session, cookies, and env' do
      expect(simulation).to receive(:run)

      expect(Pakyow::TestHelp::Simulator).to receive(:new).with(
        name,
        method: method,
        params: with,
        session: session,
        cookies: cookies,
        env: env
      ).and_return(simulation)

      instance.simulate(
        name,
        method: method,
        with: with,
        session: session,
        cookies: cookies,
        env: env
      )
    end
  end

  describe 'http methods' do
    it 'creates a method for each http method' do
      Pakyow::RouteEval::HTTP_METHODS.each do |method|
        expect(Pakyow::TestHelp::Helpers.method_defined?(method)).to eq(true)
      end
    end

    it 'should forward calls to simulate' do
      expect(instance).to receive(:simulate).with(:foo, method: :get)
      instance.get(:foo)
    end
  end
end
