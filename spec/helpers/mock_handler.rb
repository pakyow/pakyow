module Pakyow
  module TestHelp
    class MockHandler
      Rack::Handler.register :mock, self

      def self.run(app, *args)
        app
      end
    end
  end
end
