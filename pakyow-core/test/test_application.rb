require 'test/test_presenter'

class TestApplication < Pakyow::Application
  configure(:development) do
    app.auto_reload = true
    app.errors_in_browser = true
  end
  
  configure(:testing) do
    app.auto_reload = false
    app.errors_in_browser = false
    app.public_dir = 'test'
  end
  
  configure(:production) do
    server.port = 8000
  end
  
  configure(:presenter) do
    app.presenter = TestPresenter
  end
  
  routes do    
  end
  
  error(404, :ApplicationController, :handle_404)
  error(500) {}
end
