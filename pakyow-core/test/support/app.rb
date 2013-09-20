Pakyow::App.define do
  configure(:global) do
    $global_config_was_executed = true
    $env_overwrites_global_config = false
  end

  configure(:test) do
    $env_overwrites_global_config = true
    app.src_dir = File.join(Dir.pwd, 'test', 'support', 'loader')
  end

  routes(:redirect) do
    get :redirect_route, '/redirect' do
    end
  end
end

class Pakyow::App
  attr_accessor :static_handler, :static
  
  # This keeps the app from actually being run.
  def self.detect_handler
    TestHandler
  end
  
  def self.reset(do_reset)
    if do_reset
      Pakyow.app = nil
      Pakyow::Config::Base.reset!
      
      @prepared = false
      @running = false
      @staged = false
      
      @routes_proc = nil
      @status_proc = nil
    end
    
    return self
  end
end

class TestHandler
  def self.run(*args)
  end
end
