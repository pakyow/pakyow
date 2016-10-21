require 'spec_helper'
require 'pakyow/core/middleware/logger'

RSpec.describe Pakyow::Middleware::Logger do
  before do
    allow(Pakyow).to receive(:logger).and_return(double.as_null_object)
  end

  let :app do
    double
  end

  let :instance do
    Pakyow::Middleware::Logger.new(app)
  end

  let :env do
    {}
  end

  let :res do
    [200, ['foo'], {}]
  end

  let :req_logger do
    double.as_null_object
  end

  before do
    allow(Pakyow).to receive(:app).and_return(app)
    allow(app).to receive(:call).and_return(res)
  end

  describe '#call' do
    it 'exists' do
      expect(instance).to respond_to(:call)
    end

    it 'accepts one arg' do
      expect(instance.method(:call).arity).to eq(1)
    end

    context 'when called' do
      before do
        allow(Pakyow::Logger::RequestLogger).to receive(:new).with(:http).and_return(req_logger)
        instance.call(env)
      end

      it 'creates a new http request logger' do
        expect(Pakyow::Logger::RequestLogger).to have_received(:new).with(:http)
      end

      it 'sets rack.logger to request logger' do
        expect(env['rack.logger']).to be(req_logger)
      end

      it 'logs the prologue' do
        expect(req_logger).to have_received(:prologue).with(env)
      end

      it 'logs the epilogue' do
        expect(req_logger).to have_received(:epilogue).with(res)
      end

      # FIXME: this is tricky
      it 'calls the app between prologue and epilogue'

      it 'returns the result of calling the app' do
        expect(instance.call(env)).to be(res)
      end
    end
  end
end
