require 'support/helper'

# TODO: finish moving over namespace specs from `set_spec`
RSpec.describe 'route namespaces' do
  include ReqResHelpers
  include RouteTestHelpers

  before do
    Pakyow::App.stage(:test)
    @context = Pakyow::CallContext.new(mock_request.env)
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))
  end

  let :set do
    Pakyow::RouteSet.new
  end

  let :fn1 do
    -> {}
  end

  let :fn2 do
    -> {}
  end

  let :fn3 do
    -> {}
  end

  let :fn4 do
    -> {}
  end

  context 'when two routes are defined in the namespace with before hooks' do
    before do
      fn1 = self.fn1
      fn2 = self.fn2
      fn3 = self.fn3
      fn4 = self.fn4

      set.eval do
        namespace :ns, '/ns' do
          get '/1', before: [fn1], &fn2
          get '/2', before: [fn3], &fn4
        end
      end
    end

    describe 'the second route' do
      let :fns do
        set.match('/ns/2', :get)[0][3]
      end

      it 'has the proper number of fns' do
        expect(fns.count).to eq(2)
      end

      it 'includes the proper fns' do
        expect(fns[0]).to eq fn3
        expect(fns[1]).to eq fn4
      end
    end
  end
end
