module Pakyow
  module Presenter
    class ViewContext
      include Helpers
      
      def initialize(context)
        @context = context
        self
      end
      
      def context
        @context
      end
      
      def method_missing(method, *args)
        Pakyow.app.presenter.current_context.send(method, *args)
      end
    end
  end
end
