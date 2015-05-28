require 'support/helper'

describe 'Request' do
  include ReqResHelpers

  before do
    @request = mock_request('/foo/', :get, { 'HTTP_REFERER' => '/bar/' })
  end

  it 'extends rack request' do
    expect(Rack::Request).to eq Pakyow::Request.superclass
  end

  it 'path calls path info' do
    expect(@request.path).to eq @request.path_info
  end

  it 'method is proper format' do
    expect(:get).to eq @request.method
  end

  it 'url is split' do
    expect(1).to eq @request.path_parts.length
    expect('foo').to eq @request.path_parts[0]
  end

  it 'referer is split' do
    expect(1).to eq @request.referer_parts.length
    expect('bar').to eq @request.referer_parts[0]
  end

  it 'parses json body' do
    env = @request.instance_variable_get(:@env)
    env['rack.input'] = StringIO.new('{"hello": "goodbye"}')
    @request.instance_variable_set(:@env, env)
    expect('goodbye').to eq @request.params[:hello]
  end

  it 'handles bad json' do
    env = @request.instance_variable_get(:@env)
    env['rack.input'] = StringIO.new('{"hello": "goodbye"')
    @request.instance_variable_set(:@env, env)
    expect(nil).to eq @request.params[:hello]
  end
end
