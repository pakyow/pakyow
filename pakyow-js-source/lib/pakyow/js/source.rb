# frozen_string_literal: true

require "pakyow/js/source/version"

module Pakyow
  module JS
    module Source
      def self.pack_path
        File.expand_path("../../../assets/packs", __FILE__)
      end
    end
  end
end
