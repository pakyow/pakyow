require_relative 'support/int_helper'

context 'when testing a route' do
  it 'routes to route by path' do
    get '/' do |sim|
      expect(sim.status).to eq(200)
    end
  end

  it 'routes to route by name' do
    get :default do |sim|
      expect(sim.status).to eq(200)
    end
  end

  it 'routes to grouped route by name' do
    get foo: :bar do |sim|
      expect(sim.status).to eq(200)
    end
  end

  describe 'setting up a context' do
    before do
      @sim = get :default
    end

    it 'respects the context' do
      expect(@sim.status).to eq(200)
    end
  end

  describe 'the raw response code' do
    it 'equals 200 for successful requests' do
      get :default do |sim|
        expect(sim.status).to eq(200)
      end
    end

    it 'equals 404 for requests to missing routes' do
      get '/missing' do |sim|
        expect(sim.status).to eq(404)
      end
    end

    it 'equals 500 for requests to failing routes' do
      get :fail do |sim|
        expect(sim.status).to eq(500)
      end
    end
  end

  describe 'the nice response code' do
    it 'equals :ok for successful requests' do
      get :default do |sim|
        expect(sim.status).to eq(:ok)
      end
    end
  end

  describe 'the response type' do
    it 'exposes the raw response type' do
      get :default do |sim|
        expect(sim.type).to eq('text/html;charset=utf-8')
      end
    end

    it 'exposes the nice default response type' do
      get :default do |sim|
        expect(sim.format).to eq(:html)
      end
    end

    it 'exposes the nice non-default response type' do
      get '/index.json' do |sim|
        expect(sim.format).to eq(:json)
      end
    end
  end

  context 'with params' do
    it 'recognizes the params' do
      get :default, with: { foo: 'bar' } do |sim|
        expect(sim.req.params[:foo]).to eq('bar')
      end
    end
  end

  context 'with format' do
    it 'recognizes the format' do
      get '/index.json' do |sim|
        expect(sim.req.format).to eq(:json)
      end
    end
  end

  context 'with session' do
    it 'recognizes the session' do
      get :default, session: { foo: 'bar' } do |sim|
        expect(sim.req.session[:foo]).to eq('bar')
      end
    end
  end

  context 'with cookie' do
    it 'recognizes the cookie' do
      get :default, cookies: { foo: 'bar' } do |sim|
        expect(sim.req.cookies[:foo]).to eq('bar')
      end
    end
  end

  context 'with env params', :env do
    it 'recognizes the env params' do
      get :default, env: { foo: 'bar' } do |sim|
        expect(sim.req.env['foo']).to eq('bar')
      end
    end
  end
end
