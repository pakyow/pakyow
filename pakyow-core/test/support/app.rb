class TestApplication < Pakyow::Application
  configure(:test) {
    app.src_dir = File.join(Dir.pwd, 'test', 'support', 'loader')
  }

  # OVERRIDING
  
  attr_accessor :static_handler, :static
  
  # This keeps the app from actually being run.
  def self.detect_handler
    TestHandler
  end
  
  def self.reset(do_reset)
    if do_reset
      Pakyow.app = nil
      Pakyow::Configuration::Base.reset!
      
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
