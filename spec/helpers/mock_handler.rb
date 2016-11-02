module Pakyow
  module TestHelp
    class MockHandler
      Rack::Handler.register :mock, self

      def self.run(*args)
        return args
      end
    end
  end
end
