module Pakyow
  module Commands
    module ConsoleMethods
      def reload
        puts "Reloading..."
        Pakyow.app.reload
      end
    end
  end
end
