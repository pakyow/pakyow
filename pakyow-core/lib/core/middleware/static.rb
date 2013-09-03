module Pakyow
  module Middleware
    class Static
      def initialize(app)
        @app = app
      end

      def call(env)
        static, resource_path = is_static?(env)

        if static
          catch(:halt) do
            app = Pakyow.app.dup
            app.response = Response.new
            app.request = Request.new(env)
            app.send(File.open(resource_path))
          end
        else
          @app.call(env)
        end
      end

      private

      def is_static?(env)
        return false unless env['PATH_INFO'] =~ /\.(.*)$/

        Config::App.resources.each_pair do |name, path|
          resource_path = File.join(path, env['PATH_INFO'])
          next unless File.exists?(resource_path)
          return true, resource_path
        end

        return false
      end
    end
  end
end

