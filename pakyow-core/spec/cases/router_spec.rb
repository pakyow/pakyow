require 'support/helper'

describe 'Router' do
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = AppContext.new(mock_request, mock_response)
    Pakyow.app.reload
  end

  it 'is a singleton' do
    expect(Router.instance).to eq Router.instance
  end

  it 'sets are registered' do
    test = {}
    Router.instance.set(:test) {
      test[:set_registered] = true
    }

    expect(test[:set_registered]).to eq(true)
  end

  it 'has routes that can be accessed by name' do
    Router.instance.set(:test) {
      get('foo', :foo) {}
    }

    expect(Router.instance.route(:foo)).to_not be_nil
    expect{ Router.instance.route(:bar) }.to raise_error MissingRoute
  end

  it 'fns are called in order' do
    fn_calls = []
    Router.instance.set(:test) {
      fn(:one) {
        fn_calls << 1
      }

      fn(:two) {
        fn_calls << 2
      }

      fn(:three) {
        fn_calls << 3
      }

      default [fn(:one), fn(:two), fn(:three)]
    }

    Router.instance.perform(AppContext.new(mock_request))
    expect([1, 2, 3]).to eq fn_calls
  end

  it 'requests can be rerouted' do
    fn_calls = []
    Router.instance.set(:test) {
      default {
        app.reroute('foo')
      }

      get('foo') {
        fn_calls << :rerouted
      }
    }

    Router.instance.perform(AppContext.new(mock_request))
    expect([:rerouted]).to eq fn_calls
  end

  it 'requests can be rerouted with method' do
    fn_calls = []
    Router.instance.set(:test) {
      default {
        app.reroute('foo', :put)
      }

      put('foo') {
        fn_calls << :rerouted
      }
    }

    Router.instance.perform(AppContext.new(mock_request))
    expect([:rerouted]).to eq fn_calls
  end

  it 'handler can be called' do
    fn_calls = []
    Router.instance.set(:test) {
      default {
        app.handle(500)
      }

      handler(500) {
        fn_calls << :handled
      }
    }

    res = Response.new
    Pakyow.app.context = AppContext.new(nil, res)
    Router.instance.perform(AppContext.new(mock_request))

    expect([:handled]).to eq fn_calls
    expect(500).to eq res.status
  end
end
