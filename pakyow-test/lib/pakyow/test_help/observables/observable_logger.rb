module Pakyow
  module TestHelp
    class ObservableLogger
      def initialize
        @io = StringIO.new
        @logger = Logger::RequestLogger.new(:test, logger: ::Logger.new(@io))
        @logs = {}
      end

      def include?(string)
        @io.string.include?(string)
      end

      def method_missing(method, *args, &block)
        @logger.send(method, *args, &block)
      end
    end
  end
end
