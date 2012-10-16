module Pakyow
  module Middleware
    class Logger
      def initialize(app)
        @app = app
      end
      
      def call(env)
        result = nil
        difference = time { |began_at|
          Log.enter "Processing #{env['PATH_INFO']} (#{env['REMOTE_ADDR']} at #{began_at}) [#{env['REQUEST_METHOD']}]"
          
          if error = catch(:error) { 
                      result = @app.call(env)
                      nil 
                    }
            Log.enter "[500] #{error}\n"
            Log.enter error.backtrace.join("\n") + "\n\n"
            
            result = Pakyow.app.response.finish
          end
        }
        
        Log.enter "Completed in #{difference}ms | #{Pakyow.app.response.status} | [#{Pakyow.app.request.url}]"
        Log.enter

        result
      end

      def time
        s = Time.now
        yield(s)
        (Time.now.to_f - s.to_f) * 1000.0
      end
    end
  end
end
