module Pakyow
  class Logger
    def initialize(app)
      @app = app
    end
    
    def call(env)
      began_at = Time.now
      
      Log.enter "Processing #{env['PATH_INFO']} (#{env['REMOTE_ADDR']} at #{began_at}) [#{env['REQUEST_METHOD']}]"
      
      result = nil
      
      if error = catch(:error) { 
                  result = @app.call(env)
                  nil 
                }
        Log.enter "[500] #{error}\n"
        Log.enter error.backtrace.join("\n") + "\n\n"
        
        result = @app.response.finish
      end
      
      ended_at = Time.now.to_f
      difference = ((ended_at - began_at.to_f) * 1000).to_f

      Log.enter "Completed in #{difference}ms | #{app.response.status} | [#{app.request.url}]"
      Log.enter
      
      result
    end
  end
end
