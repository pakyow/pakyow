# frozen_string_literal: true

require "pastel"

module Pakyow
  module Support
    module CLI
      def self.style
        @style ||= Pastel.new
      end
    end
  end
end
