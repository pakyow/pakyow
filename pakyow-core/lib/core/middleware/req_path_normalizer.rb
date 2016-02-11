require 'core/call_context'

module Pakyow
  module Middleware
    Pakyow::App.middleware do |builder|
      builder.use Pakyow::Middleware::ReqPathNormalizer
    end

    # Rack compatible middleware that normalize the path if contains '//'
    # or has a trailing '/', it replace '//' with '/', remove trailing `/`
    # and issue a 301 redirect to the normalized path.
    #
    # @api public
    class ReqPathNormalizer
      def initialize(app)
        @app = app
      end

      def call(env)
        path = env['PATH_INFO']

        if double_slash?(path) || tail_slash?(path)
          CallContext.new(env).redirect(normalize_path(path), 301)
        else
          @app.call(env)
        end
      end

      def normalize_path(path)
        path
          .gsub('//', '/')
          .gsub(/(\/)+$/, '')
      end

      def double_slash?(path)
        path.include?('//')
      end

      def tail_slash?(path)
        (/(\/)+$/ =~ path).nil? ? false : true
      end
    end
  end
end
