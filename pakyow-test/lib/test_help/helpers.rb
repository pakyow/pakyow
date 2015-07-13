require_relative 'simulator'

module Pakyow
  module TestHelp
    module Helpers
      def simulate(name_or_path, method: :get, with: {}, session: {}, cookies: {}, env: {}, &block)
        sim = Pakyow::TestHelp::Simulator.new(
          name_or_path,
          method: method,
          params: with,
          session: session,
          cookies: cookies,
          env: env
        )

        sim.run(&block)
      end

      alias_method :sim, :simulate

      Pakyow::RouteEval::HTTP_METHODS.each do |method|
        define_method method do |name_or_path, **args, &block|
          simulate(name_or_path, method: method, **args, &block)
        end
      end
    end
  end
end
