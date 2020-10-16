# frozen_string_literal: true

module Pakyow
  class Filewatcher
    # @api private
    class Status
      def initialize
        @state = :created
        @lock = Mutex.new
      end

      # Allow status to change at runtime (so the file watcher can be paused and resumed).
      #
      def insulated?
        true
      end

      # Define methods for changing and introspecting the current status.
      #
      %i[running paused stopped].each do |state|
        define_method :"#{state}!" do |&block|
          changed = @lock.synchronize {
            if @state == state
              false
            else
              @state = state
              true
            end
          }

          block&.call if changed
        end

        define_method :"#{state}?" do
          @state == state
        end
      end
    end
  end
end
