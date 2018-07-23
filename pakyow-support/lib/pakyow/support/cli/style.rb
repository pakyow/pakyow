# frozen_string_literal: true

require "pastel"

module Pakyow
  module Support
    module CLI
      def self.style
        @pastel ||= Pastel.new
      end
    end
  end
end
