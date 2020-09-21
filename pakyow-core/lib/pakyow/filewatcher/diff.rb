# frozen_string_literal: true

module Pakyow
  class Filewatcher
    class Diff
      def initialize
        @changes = {}
        @lock = Mutex.new
      end

      %i[added changed removed].each do |event|
        define_method :"#{event}" do |path|
          @lock.synchronize do
            @changes[path] = event
          end
        end
      end

      # Returns `true` if `path` is included in this diff.
      #
      def include?(path)
        @changes.include?(path)
      end

      # Yields each changed path and event.
      #
      def each_change(&block)
        return to_enum(:each_change) unless block_given?

        @changes.each_pair(&block)
      end
      alias_method :each_pair, :each_change

      # Yields each changed path.
      #
      def each_changed_path(&block)
        return to_enum(:each_changed_path) unless block_given?

        @changes.each_key(&block)
      end
    end
  end
end
