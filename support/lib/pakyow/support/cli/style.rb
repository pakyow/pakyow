# frozen_string_literal: true

module Pakyow
  module Support
    module CLI
      def self.style
        unless defined?(@__style)
          require "pastel"
          @__style = Pastel.new
        end

        @__style
      end
    end
  end
end
