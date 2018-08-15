# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Security
    class Error < Pakyow::Error
    end

    class InsecureRequest < Error
    end
  end
end
