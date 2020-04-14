# frozen_string_literal: true

require "protocol/http/headers"

module Pakyow
  class Connection
    class Headers < Protocol::HTTP::Headers
      def [](key)
        to_h[key.downcase]
      end
    end
  end
end
