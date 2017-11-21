# frozen_string_literal: true

module Pakyow
  module TestHelp
    class MockPresenter
      attr_reader :calls

      def initialize(presenter)
        @presenter = presenter
        @calls = []
      end

      def method_missing(method, *args, &block)
        ret = @presenter.send(method, *args, &block)
        @calls << [method, args]
        ret
      end
    end
  end
end
