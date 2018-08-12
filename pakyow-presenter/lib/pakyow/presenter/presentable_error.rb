# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  class Error
    def [](key)
      if respond_to?(key)
        public_send(key)
      else
        nil
      end
    end

    def include?(key)
      respond_to?(key)
    end
  end
end
