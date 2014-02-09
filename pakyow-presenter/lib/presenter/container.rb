module Pakyow
  module Presenter
    class Container
      def initialize(contents = '', format = :html)
        @contents = contents
        @format = format
      end

      def to_html
        @contents
      end
      alias_method :to_s, :to_html

      def to_view
        View.new(@contents, @format)
      end
    end
  end
end
