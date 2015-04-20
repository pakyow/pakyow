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

    get :present, '/present/:path' do
      presenter.path = params[:path]
    end

    get :title, '/title/:title' do
      presenter.path = '/'
      view.title = params[:title]
    end

    get :scoped, '/scoped' do
      if data = params[:data]
        view.scope(:post).apply(data)
      end
    end
  end
end
