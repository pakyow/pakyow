require 'spec_helper'
require 'core/middleware/req_path_normalizer'

describe Pakyow::Middleware::ReqPathNormalizer do
  let :app do
    double
  end

  let :instance do
    Pakyow::Middleware::ReqPathNormalizer.new(app)
  end

  let :env do
    {
      'PATH_INFO' => path,
      'REQUEST_METHOD' => method
    }
  end

  let :path do
    '//test_page'
  end

  let :normalized_path do
    instance.normalize_path(env['PATH_INFO'])
  end

  let :method do
    'GET'
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

    context 'path contains //' do
      it 'issues a 301 redirect with the normalized path' do
        expect_any_instance_of(Pakyow::CallContext).to receive(:redirect).with(normalized_path, 301)
        instance.call(env)
      end
    end

    context 'normal path' do
      before do
        env['PATH_INFO'] = '/test_page'
      end

      it 'routes to proper page' do
        expect(app).to receive(:call)
        instance.call(env)
      end
    end
  end

  describe '#normalize_path' do
    it 'replaces // with /' do
      expect(instance.normalize_path(env['PATH_INFO'])).to eq('/test_page')
    end

    it 'removes trailing /' do
      env['PATH_INFO'] = '/test_page/'
      expect(instance.normalize_path(env['PATH_INFO'])).to eq('/test_page')
    end

    it 'replaces // with / and removes trailing /' do
      env['PATH_INFO'] = '//test_page/'
      expect(instance.normalize_path(env['PATH_INFO'])).to eq('/test_page')
    end
  end

  describe '#tail_slash?' do
    context 'when path contains only a trailing /' do
      it 'does not remove the trailing /' do
        expect(instance.tail_slash?('/')).to eq(false)
      end
    end
  end
end
