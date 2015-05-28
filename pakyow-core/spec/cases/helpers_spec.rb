require 'support/helper'

describe 'Helpers' do
  include Pakyow::Helpers
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = AppContext.new(mock_request, mock_response)
  end

  it 'test app returned' do
    expect(Pakyow.app.class).to eq Pakyow::App
  end

  it 'test app request returned' do
    r = :test
    Pakyow.app.context = AppContext.new(r)
    expect(r).to eq Pakyow.app.request
    expect(r).to eq Pakyow.app.req
  end

  it 'test app response returned' do
    r = :test
    Pakyow.app.context = AppContext.new(nil, r)
    expect(r).to eq Pakyow.app.response
    expect(r).to eq Pakyow.app.res
  end

  it 'test router lookup returned' do
    expect(Pakyow.app.router).to be_a Pakyow::RouteLookup
  end

  it 'test params returned' do
    Pakyow.app.context = AppContext.new(mock_request)
    expect(Pakyow.app.params).to eq Pakyow.app.params
  end

  it 'test session returned' do
    Pakyow.app.context = AppContext.new(mock_request)
    expect(Pakyow.app.session).to eq Pakyow.app.request.session
  end

  it 'test cookies returned' do
    Pakyow.app.context = AppContext.new(mock_request)
    expect(Pakyow.app.cookies).to eq Pakyow.app.cookies
  end

  it 'test app helpers are included in app' do
    expect(Pakyow::App.ancestors).to include(Pakyow::AppHelpers)
  end
end
