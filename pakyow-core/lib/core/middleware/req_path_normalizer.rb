require 'core/call_context'

module Pakyow
  module Middleware
    # Rack compatible middleware that normalize the path if contains '//',
    # it replace '//' with '/' and issue a 301 redirect to the new path.
    #
    # @api public
    class ReqPathNormalizer
      def initialize(app)
        @app = app
      end

      def call(env)
        if env['PATH_INFO'].include? '//'
          CallContext.new(env).redirect(normalize_path(env['PATH_INFO']), 301)
        else
          @app.call(env)
        end
      end

      def normalize_path(path)
        path.gsub('//', '/')
      end
    end
  end
end
