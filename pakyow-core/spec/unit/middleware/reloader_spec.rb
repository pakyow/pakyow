require 'spec_helper'
require 'pakyow/core/middleware/reloader'

describe Pakyow::Middleware::Reloader do
  let :app do
    double
  end

  let :instance do
    Pakyow::Middleware::Reloader.new(app)
  end

  let :env do
    {}
  end

  before do
    allow(Pakyow).to receive(:app).and_return(app)
    allow(app).to receive(:call)
  end

  describe '#call' do
    it 'exists' do
      expect(instance).to respond_to(:call)
    end

    it 'accepts one arg' do
      expect(instance.method(:call).arity).to eq(1)
    end

    it 'calls reload on Pakyow.app' do
      expect(app).to receive(:reload)
      instance.call(env)
    end
  end
end
