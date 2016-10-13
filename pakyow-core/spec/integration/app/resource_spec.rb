require 'support/helper'

# TODO: rewrite these
# RSpec.describe 'defining a resource' do
#   include ReqResHelpers

#   before do
#     Pakyow.setup(env: :test)
#     @context = Pakyow::CallContext.new(mock_request.env)
#     @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))

#     Pakyow::App.resource :test, "tests" do
#       list do; end
#     end
#   end

#   it 'creates a route set for the resource name' do
#     expect(Pakyow::Router.instance.sets[:test]).to be_kind_of Pakyow::RouteSet
#   end

#   describe 'the route set block' do
#     let(:route_set_block) { Pakyow.app.routes[:test] }

#     it 'exists' do
#       expect(route_set_block).to be_kind_of Proc
#     end

#     context 'when evaluated' do
#       let(:set) { Pakyow::RouteSet.new }

#       it 'creates restful routes with resource name, path, and block' do
#         set.eval(&route_set_block)

#         expect(set.match("tests", :get)).not_to be_nil
#       end
#     end
#   end
# end
