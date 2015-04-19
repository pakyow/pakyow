Pakyow::App.define do
  configure :test do
    app.log = false
    app.log_output = false

    presenter.view_stores[:default] = File.join(File.dirname(__FILE__), 'views')
  end

  routes do
    default do; end

    get :fail, '/fail' do
      fail!
    end

    get :redirect, '/redirect' do
      redirect :default
    end

    get :reroute, '/reroute' do
      reroute :default
    end

    group :foo do
      get :bar, '/bar' do; end
    end
  end
end
