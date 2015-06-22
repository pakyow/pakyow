require 'support/helper'

describe 'Router' do
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = Pakyow::AppContext.new(mock_request, mock_response)
    Pakyow.app.reload
  end

  it 'is a singleton' do
    expect(Pakyow::Router.instance).to eq Pakyow::Router.instance
  end

  it 'sets are registered' do
    test = {}
    Pakyow::Router.instance.set(:test) {
      test[:set_registered] = true
    }

    expect(test[:set_registered]).to eq(true)
  end

  it 'has routes that can be accessed by name' do
    Pakyow::Router.instance.set(:test) {
      get('foo', :foo) {}
    }

    expect(Pakyow::Router.instance.route(:foo)).to_not be_nil
    expect{ Pakyow::Router.instance.route(:bar) }.to raise_error Pakyow::MissingRoute
  end

  it 'fns are called in order' do
    fn_calls = []
    Pakyow::Router.instance.set(:test) {
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

    Pakyow::Router.instance.perform(Pakyow::AppContext.new(mock_request))
    expect(fn_calls).to eq [1, 2, 3]
  end

  it 'requests can be rerouted' do
    fn_calls = []
    Pakyow::Router.instance.set(:test) {
      default {
        app.reroute('foo')
      }

      get('foo') {
        fn_calls << :rerouted
      }
    }

    Pakyow::Router.instance.perform(Pakyow::AppContext.new(mock_request))
    expect(fn_calls).to eq [:rerouted]
  end

  it 'requests can be rerouted with method' do
    fn_calls = []
    Pakyow::Router.instance.set(:test) {
      default {
        app.reroute('foo', :put)
      }

      put('foo') {
        fn_calls << :rerouted
      }
    }

    Pakyow::Router.instance.perform(Pakyow::AppContext.new(mock_request))
    expect(fn_calls).to eq [:rerouted]
  end

  it 'handler can be called' do
    fn_calls = []
    Pakyow::Router.instance.set(:test) {
      default {
        app.handle(500)
      }

      handler(500) {
        fn_calls << :handled
      }
    }

    res = Pakyow::Response.new
    Pakyow.app.context = Pakyow::AppContext.new(nil, res)
    Pakyow::Router.instance.perform(Pakyow::AppContext.new(mock_request))

    expect(fn_calls).to eq [:handled]
    expect(res.status).to eq 500
  end
end
