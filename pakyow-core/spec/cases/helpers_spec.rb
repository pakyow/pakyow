require 'support/helper'

describe 'Pakyow Helper' do
  include Pakyow::Helpers
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.context = Pakyow::AppContext.new(mock_request, mock_response)
  end

  it 'returns app' do
    expect(Pakyow.app.class).to eq Pakyow::App
  end

  it 'returns app request' do
    r = :test
    Pakyow.app.context = Pakyow::AppContext.new(r)
    expect(Pakyow.app.request).to eq r
    expect(Pakyow.app.req).to eq r
  end

  it 'returns app response' do
    r = :test
    Pakyow.app.context = Pakyow::AppContext.new(nil, r)
    expect(Pakyow.app.response).to eq r
    expect(Pakyow.app.res).to eq r
  end

  it 'returns router lookup' do
    expect(Pakyow.app.router).to be_a Pakyow::RouteLookup
  end

  it 'returns params' do
    Pakyow.app.context = Pakyow::AppContext.new(mock_request)
    expect(Pakyow.app.params).to eq Pakyow.app.params
  end

  it 'returns session' do
    Pakyow.app.context = Pakyow::AppContext.new(mock_request)
    expect(Pakyow.app.session).to eq Pakyow.app.request.session
  end

  it 'returns cookies' do
    Pakyow.app.context = Pakyow::AppContext.new(mock_request)
    expect(Pakyow.app.cookies).to eq Pakyow.app.cookies
  end

  it 'are included in app' do
    expect(Pakyow::App.ancestors).to include(Pakyow::AppHelpers)
  end
end
