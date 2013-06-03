module Pakyow
  module Middleware
    class Static
      def initialize(app)
        @app = app
      end
      
      def call(env)
        if is_static?(env)
          catch(:halt) do
            app = Pakyow.app.dup
            app.response = Response.new
            app.request = Request.new(env)
            app.send(File.open(File.join(Config::Base.app.public_dir, env['PATH_INFO'])))
          end
        else
          @app.call(env)
        end
      end
      
      private
      
      def is_static?(env)
        env['PATH_INFO'] =~ /\.(.*)$/ && File.exists?(File.join(Config::Base.app.public_dir, env['PATH_INFO']))
      end
    end
  end
end
