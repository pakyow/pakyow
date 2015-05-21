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
      Pakyow.app.redirect(location)
    rescue
    end

    expect(302).to eq Pakyow.app.response.status
    expect(location).to eq Pakyow.app.response.header['Location']
  end

  it 'issues route lookup on redirect' do
    reset

    begin
      Pakyow.app.redirect(:redirect_route)
    rescue
    end

    expect(302).to eq Pakyow.app.response.status
    expect('/redirect').to eq Pakyow.app.response.header['Location']
  end

  it 'respects status on redirect' do
    reset
    location = '/'
    begin
      Pakyow.app.redirect(location, 301)
    rescue
    end

    expect(301).to eq Pakyow.app.response.status
    expect(location).to eq Pakyow.app.response.header['Location']
  end

  it 'halts on redirect' do
    reset

    begin
      Pakyow.app.redirect('/')
    rescue
      @halted = true
    end

    expect(@halted).to eq true
  end

  it 'can be rerouted to new path' do
    reset

    path = '/foo/'
    router = MockRouter.new
    Pakyow.app.router = router
    Pakyow.app.context = AppContext.new(mock_request(path), mock_response)
    Pakyow.app.reroute(path)

    expect(:get).to eq Pakyow.app.request.method
    expect(path).to eq Pakyow.app.request.path
    expect(router.reroute).to eq true
  end

  it 'can be rerouted to new path with method' do
    reset

    path = '/foo/'
    method = :put
    router = MockRouter.new
    Pakyow.app.router = router
    Pakyow.app.context = AppContext.new(mock_request(path), mock_response)
    Pakyow.app.reroute(path, method)

    expect(Pakyow.app.request.method).to eq method
    expect(Pakyow.app.request.path).to eq path
    expect(router.reroute).to eq true
  end

  it 'can handle 500 code' do
    reset

    router = MockRouter.new
    Pakyow.app.router = router
    Pakyow.app.handle(500)

    expect(router.handle).to eq true
  end

  it 'can send data' do
    reset

    data = 'foo'

    catch(:halt) {
      Pakyow.app.send(data)
    }

    expect(Pakyow.app.response.body).to eq [data]
    expect(Pakyow.app.response.header['Content-Type']).to eq 'text/html'
  end

  it 'can send data with type' do
    reset

    data = 'foo'
    type = 'text'

    catch(:halt) {
      Pakyow.app.send(data, type)
    }

    expect(Pakyow.app.response.body).to eq [data]
    expect(Pakyow.app.response.header['Content-Type']).to eq type
  end

  it 'can send a file' do
    reset

    path = File.join(File.dirname(__FILE__), '../../support/helpers/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'))
    }

    expect(Pakyow.app.response.body).to eq [data]
    expect(Pakyow.app.response.header['Content-Type']).to eq 'text/plain'
  end

  it 'can send a file with type' do
    reset
    Pakyow.app.context = AppContext.new(mock_request, mock_response)

    type = 'text/plain'
    path = File.join(File.dirname(__FILE__), '../../support/helpers/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'), type)
    }

    expect([data]).to eq Pakyow.app.response.body
    expect(type).to eq Pakyow.app.response.header['Content-Type']
  end

  it 'can send a file with type as attachment' do
    reset
    Pakyow.app.context = AppContext.new(mock_request, mock_response)

    as = 'foo.txt'
    type = 'text/plain'
    path = File.join(File.dirname(__FILE__), '../../support/helpers/foo.txt')

    data = File.open(path, 'r').read

    catch(:halt) {
      Pakyow.app.send(File.open(path, 'r'), type, as)
    }

    expect([data]).to eq Pakyow.app.response.body
    expect(type).to eq Pakyow.app.response.header['Content-Type']
    expect("attachment; filename=#{as}").to eq Pakyow.app.response.header['Content-disposition']
  end
end
