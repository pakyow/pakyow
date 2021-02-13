# frozen_string_literal: true

module Pakyow
  module Support
    class Deprecator
      # Global deprecator instance that supports forwarding.
      #
      # @api private
      class Global < Deprecator
        def initialize(...)
          super

          @forwards = []
        end

        def >>(other)
          unless @forwards.include?(other)
            @forwards << other
          end
        end

        def forwarding?
          @forwards.any?
        end

        def deprecated(*args, **kwargs)
          if forwarding?
            @forwards.each do |forward|
              forward.deprecated(*args, **kwargs)
            end
          else
            super
          end
        end

        def ignore
          if forwarding?
            begin
              @forwards.each do |forward|
                forward.send(:replace, Reporters::Null)
              end

              yield
            ensure
              @forwards.each do |forward|
                forward.send(:replace, nil)
              end
            end
          else
            super
          end
        end
      end
    end
  end
end
