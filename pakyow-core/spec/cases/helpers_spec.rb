require 'support/helper'

RSpec.describe 'Pakyow Helper' do
  include Pakyow::Helpers
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    @context = Pakyow::CallContext.new(mock_request.env)
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))
  end

  it 'returns app' do
    expect(Pakyow.app.class).to eq Pakyow::App
  end

  it 'returns app request' do
    r = :test
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(r, mock_response))
    expect(@context.request).to eq r
    expect(@context.req).to eq r
  end

  it 'returns app response' do
    r = :test
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, r))
    expect(@context.response).to eq r
    expect(@context.res).to eq r
  end

  it 'returns router lookup' do
    expect(@context.router).to be_a Pakyow::RouteLookup
  end

  it 'returns params' do
    expect(@context.params).to eq @context.request.params
  end

  it 'returns session' do
    expect(@context.session).to eq @context.request.session
  end

  it 'returns cookies' do
    expect(@context.cookies).to eq @context.request.cookies
  end
end
