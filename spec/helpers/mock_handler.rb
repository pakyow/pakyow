require "rack"

module Pakyow
  module TestHelp
    class MockHandler
      Rack::Handler.register :mock, self

      def self.run(app, *args)
        Pakyow.instance_exec(&Proc.new) if block_given?
        app
      end
    end
  end
end
