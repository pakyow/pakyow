require_relative 'simulation'

module Pakyow
  module TestHelp
    class Simulator
      attr_reader :env, :path, :method, :params

      def initialize(name_or_path, method: :get, params: {}, session: {}, cookies: {})
        @path   = router.path(name_or_path, params)
        @method = method
        #TODO handle complex params as form data
        @params = params
        @env    = {
          'REQUEST_METHOD'            => @method.to_s.upcase,
          'REQUEST_PATH'              => @path,
          'PATH_INFO'                 => @path,
          'QUERY_STRING'              => @params.to_a.map { |p| p.join('=') }.join('&'),
          'rack.session'              => session,
          'rack.request.cookie_hash'  => cookies,
          'rack.input'                => StringIO.new
        }
      end

      def run(&block)
        app = Pakyow.app.dup
        app.process(env)

        sim = Simulation.new(app)

        return sim unless block_given?
        yield sim
      end

      private

      def router
        Pakyow::Router.instance
      end
    end
  end
end
