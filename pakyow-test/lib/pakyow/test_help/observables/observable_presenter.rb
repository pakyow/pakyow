require_relative '../observable'

module Pakyow
  module TestHelp
    class ObservablePresenter
      include Observable
      attr_reader :presenter

      def initialize(presenter)
        @presenter = presenter
      end

      def observable
        presenter
      end
    end
  end
end
