require 'support/helper'

describe  'App Actions' do
  include ReqResHelpers
  include ActionHelpers

  it 'can be halted' do
    reset

    begin
      Pakyow.app.halt
    rescue
      @halted = true
    end

    expect(@halted).to eq true
  end

  it 'can_be_redirected' do
    reset
    location = '/'

    begin
      @context.redirect(location)
    rescue ArgumentError
    end

    expect(@context.response.status).to eq 302
    expect(@context.response.header['Location']).to eq location
  end

  it 'issues route lookup on redirect' do
    reset

    begin
      @context.redirect(:redirect_route)
    rescue ArgumentError
    end

    expect(@context.response.status).to eq 302
    expect(@context.response.header['Location']).to eq '/redirect'
  end

  it 'respects status on redirect' do
    reset
    location = '/'

    begin
      @context.redirect(location, 301)
    rescue ArgumentError
    end

    expect(@context.response.status).to eq 301
    expect(@context.response.header['Location']).to eq location
  end

  it 'halts on redirect' do
    reset

    begin
      @context.redirect('/')
    rescue ArgumentError
      @halted = true
    end

    expect(@halted).to eq true
  end

  it 'can be rerouted to new path' do
    reset

    path = '/foo/'
    router = MockRouter.new

    @context.instance_variable_set(:@router, router)
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request(path), mock_response))

    @context.reroute(path)

    expect(@context.request.method).to eq :get
    expect(@context.request.path).to eq path
    expect(router.reroute).to eq true
  end

  it 'can be rerouted to new path with method' do
    reset

    path = '/foo/'
    method = :put
    router = MockRouter.new

    @context.instance_variable_set(:@router, router)
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request(path), mock_response))

    @context.reroute(path, method)

    expect(@context.request.method).to eq method
    expect(@context.request.path).to eq path
    expect(router.reroute).to eq true
  end

  it 'can handle 500 code' do
    reset

    router = MockRouter.new
    @context.instance_variable_set(:@router, router)

    @context.handle(500)

    expect(router.handle).to eq true
  end

  it 'can send data' do
    reset

    data = 'foo'

    catch(:halt) {
      @context.send(data)
    }

    expect(@context.response.body.read).to eq data
    expect(@context.response.header['Content-Type']).to eq 'text/html;charset=utf-8'
  end

  it 'can send data with type' do
    reset

    data = 'foo'
    type = 'text'

    catch(:halt) {
      @context.send(data, type)
    }

    expect(@context.response.body.read).to eq data
    expect(@context.response.header['Content-Type']).to eq type
  end

  it 'can send a file' do
    reset

    path = File.join(File.dirname(__FILE__), '../../support/helpers/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      @context.send(File.open(path, 'r'))
    }

    expect(@context.response.body.read).to eq data
    expect(@context.response.header['Content-Type']).to eq 'text/plain'
  end

  it 'can send a file with type' do
    reset

    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))

    type = 'text/plain'
    path = File.join(File.dirname(__FILE__), '../../support/helpers/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      @context.send(File.open(path, 'r'), type)
    }

    expect(@context.response.body.read).to eq data
    expect(@context.response.header['Content-Type']).to eq type
  end

  it 'can send a file with type as attachment' do
    reset

    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))

    as = 'foo.txt'
    type = 'application/force-download'
    path = File.join(File.dirname(__FILE__), '../../support/helpers/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      @context.send(File.open(path, 'r'), type, as)
    }

    expect(@context.response.body.read).to eq data
    expect(@context.response.header['Content-Type']).to eq type
    expect(@context.response.header['Content-disposition']).to eq "attachment; filename=#{as}"
  end
end
