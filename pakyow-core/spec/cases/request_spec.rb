require 'support/helper'

describe 'Request' do
  include ReqResHelpers

  before do
    @request = mock_request('/foo/', :get, { 'HTTP_REFERER' => '/bar/' })
  end

  it 'extends rack request' do
    expect(Pakyow::Request.superclass).to eq Rack::Request
  end

  it 'path calls path info' do
    expect(@request.path).to eq @request.path_info
  end

  it 'method is proper format' do
    expect(@request.method).to eq :get
  end

  it 'url is split' do
    expect(@request.path_parts.length).to eq 1
    expect(@request.path_parts[0]).to eq 'foo'
  end

  it 'referer is split' do
    expect(@request.referer_parts.length).to eq 1
    expect(@request.referer_parts[0]).to eq 'bar'
  end

  it 'parses json body' do
    env = @request.instance_variable_get(:@env)
    env['rack.input'] = StringIO.new('{"hello": "goodbye"}')
    @request.instance_variable_set(:@env, env)
    @request.instance_variable_set(:@format, :json)
    expect(@request.params[:hello]).to eq 'goodbye'
  end
end
