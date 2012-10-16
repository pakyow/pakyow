module Pakyow
  module Middleware
    class Static
      def initialize(app)
        @app = app
      end
      
      def call(env)
        if is_static?(env)
          response = Rack::Response.new
          
          catch(:halt) do
            Pakyow.app.send_file!(File.join(Configuration::Base.app.public_dir, env['PATH_INFO']))
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
end
