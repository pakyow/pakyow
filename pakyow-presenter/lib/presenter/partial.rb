module Pakyow
  module Presenter
    class Partial < View
      attr_accessor :composer

      def invalidate!
        @composer.dirty! unless @composer.nil?
        super
      end
    end
  end
end
