# frozen_string_literal: true

module Pakyow
  module Runnable
    class Formation
      # @api private
      class All < Formation
        def service?(service)
          service.to_sym == :all
        end

        def count(service)
          if service.to_sym == :all
            super
          end
        end
      end
    end
  end
end
