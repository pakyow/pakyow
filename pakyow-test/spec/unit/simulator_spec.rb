require_relative 'support/unit_helper'
require_relative '../../lib/test_help/simulator'

describe Pakyow::TestHelp::Simulator do
  let :simulator do
    Pakyow::TestHelp::Simulator.new(
      name_or_path,
      method: method,
      params: params,
      session: session,
      cookies: cookies,
      env: env
    )
  end

  let :name_or_path do
    '/'
  end

  let :method do
    :get
  end

  let :params do
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

  describe 'initialization' do
    it 'creates an environment' do
      expect(simulator.env).to be_an_instance_of(Hash)
    end

    describe 'the created environment' do
      it 'contains REQUEST_METHOD' do
        expect(simulator.env['REQUEST_METHOD']).to eq(method.to_s.upcase)
      end

      it 'contains REQUEST_PATH' do
        expect(simulator.env['REQUEST_PATH']).to eq(name_or_path)
      end

      it 'contains PATH_INFO' do
        expect(simulator.env['PATH_INFO']).to eq(name_or_path)
      end

      it 'contains QUERY_STRING' do
        expect(simulator.env['QUERY_STRING']).to eq('foo=bar')
      end

      it 'contains rack.session' do
        expect(simulator.env['rack.session']).to eq(session)
      end

      it 'contains rack.request.cookie_hash' do
        expect(simulator.env['rack.request.cookie_hash']).to eq(cookies)
      end

      it 'contains rack.request.env' do
        expect(simulator.env['bar']).to eq('foo')
      end

      it 'contains rack.input' do
        expect(simulator.env['rack.input']).to be_an_instance_of(StringIO)
      end
    end

    it 'exposes the path' do
      expect(simulator.path).to eq(name_or_path)
    end

    it 'exposes the method' do
      expect(simulator.method).to eq(method)
    end

    it 'exposes the params' do
      expect(simulator.params).to eq(params)
    end
  end

  describe 'run' do
    it 'creates a simulation with call context' do
      expect(Pakyow::TestHelp::Simulation).to receive(:new).with(instance_of(Pakyow::CallContext))
      simulator.run
    end

    context 'and no block is given' do
      it 'returns the simulation' do
        expect(simulator.run).to be_an_instance_of(Pakyow::TestHelp::Simulation)
      end
    end

    context 'and a block is given' do
      it 'calls the block with the simulation' do
        expect { |b| simulator.run(&b) }.to yield_control
      end
    end
  end
end
