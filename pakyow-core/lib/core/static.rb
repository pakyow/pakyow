module Pakyow
  class Static
    def initialize(app)
      @app = app
    end
    
    def call(env)
      if is_static?(env)
        Pakyow.app.response = Rack::Response.new #TODO this is fugly
        
        catch(:halt) do
          Pakyow.app.send_file(File.join(Configuration::Base.app.public_dir, env['PATH_INFO']))
        end
      else
        @app.call(env)
      end
    end
    
    private
    
    def is_static?(env)
      env['PATH_INFO'] =~ /\.(.*)$/ && File.exists?(File.join(Configuration::Base.app.public_dir, env['PATH_INFO']))
    end
  end
end
