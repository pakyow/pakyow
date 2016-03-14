require 'fileutils'
require 'spec_helper'
require 'pakyow/core/middleware/static'

RSpec::Matchers.define :a_file_like do |file|
  match { |actual| actual.path == file.path }
end

describe Pakyow::Middleware::Static do
  let :app do
    double
  end

  let :instance do
    Pakyow::Middleware::Static.new(app)
  end

  let :env do
    {
      'PATH_INFO' => path,
      'REQUEST_METHOD' => method
    }
  end

  let :path do
    'foo.png'
  end

  let :method do
    'GET'
  end

  let :resources do
    { mock: './' }
  end

  let :mock_context do
    instance_double(Pakyow::CallContext)
  end

  before do
    allow(app).to receive(:call)
    allow(instance.class).to receive(:resources).and_return(resources)
    allow(mock_context).to receive(:send)
  end

  describe '#call' do
    it 'exists' do
      expect(instance).to respond_to(:call)
    end

    it 'accepts one arg' do
      expect(instance.method(:call).arity).to eq(1)
    end

    it 'checks if env is for a static file' do
      expect(instance.class).to receive(:static?).with(env)
      instance.call(env)
    end

    context 'when static' do
      before do
        allow(Pakyow::CallContext).to receive(:new).with(env).and_return(mock_context)
        allow(instance.class).to receive(:static?).and_return([true, File.join(resources[:mock], path)])
        FileUtils.touch(path)
      end

      after do
        FileUtils.rm(path)
      end

      it 'creates a call context with env' do
        expect(Pakyow::CallContext).to receive(:new).with(env).and_return(mock_context)
        instance.call(env)
      end

      it 'sends the file' do
        expect(mock_context).to receive(:send).with(a_file_like(File.open(File.join(resources[:mock], path))))
        instance.call(env)
      end

      it 'catches halt' do
        expect(mock_context).to receive(:send).and_throw(:halt)
        expect { instance.call(env) }.not_to raise_error
      end
    end

    context 'when not static' do
      before do
        allow(instance.class).to receive(:static?).and_return(false)
      end

      it 'continues by calling the app' do
        expect(app).to receive(:call)
        instance.call(env)
      end

      it 'does not create a call context' do
        expect(Pakyow::CallContext).not_to receive(:new)
        instance.call(env)
      end
    end
  end

  describe '::static?' do
    context 'when the path looks like a file' do
      context 'and the file exists' do
        before do
          FileUtils.touch(path)
        end

        after do
          FileUtils.rm(path)
        end

        describe 'the return value' do
          it 'returns true' do
            expect(instance.class.static?(env)[0]).to eq(true)
          end

          it 'returns the full path' do
            expect(instance.class.static?(env)[1]).to eq(File.join(resources[:mock], path))
          end
        end

        context 'and the file exists in multiple resources' do
          before do
            resources[:subresource] = './subresource'
            FileUtils.mkdir(resources[:subresource])
            FileUtils.touch(File.join(resources[:subresource], path))
          end

          after do
            FileUtils.rm(File.join(resources[:subresource], path))
            FileUtils.rm_r(resources[:subresource])
            resources.delete(:subresource)
          end

          it 'returns the first full path' do
            expect(instance.class.static?(env)[1]).to eq(File.join(resources[:mock], path))
          end
        end

        context 'but the request method is not GET' do
          let :method do
            'POST'
          end

          it 'returns false' do
            expect(instance.class.static?(env)).to eq(false)
          end
        end
      end

      context 'and the file does not exist' do
        it 'returns false' do
          expect(instance.class.static?(env)).to eq(false)
        end
      end
    end

    context 'when the path does not look like a file' do
      let :path do
        'foo'
      end

      context 'and the file exists' do
        before do
          FileUtils.touch(path)
        end

        after do
          FileUtils.rm(path)
        end

        it 'returns false' do
          expect(instance.class.static?(env)).to eq(false)
        end
      end

      context 'and the file does not exist' do
        it 'returns false' do
          expect(instance.class.static?(env)).to eq(false)
        end
      end
    end
  end
end
