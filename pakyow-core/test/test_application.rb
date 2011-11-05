require 'test_presenter'

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

  handlers do
    handler(:h404, 404, :ApplicationController, :handle_404)
    handler(:h500, 500) {}
  end

  # OVERRIDING
  
  attr_accessor :static_handler, :routes, :static
  
  # This keeps the app from actually being run.
  def self.detect_handler
    TestHandler
  end
  
  def self.reset(do_reset)
    if do_reset
      Pakyow.app = nil
      Pakyow::Configuration::Base.reset!
      
      @prepared = nil
      @running = nil
      @staged = nil
      @routes_proc = nil
      @status_proc = nil
    end
    
    return self
  end
  
  def register_route(route, block, method, controller = nil, action = nil, restful = false)
    @routes ||= []
    @routes << { :route => route, :block => block, :method => method, :controller => controller, :action => action }
  end
  
  def restful_actions
    @@restful_actions
  end
  
  def restful_options_for_action(action)
    restful_actions.each do |h|
      return h if h[:action] == action
    end
  end
end
