# frozen_string_literal: true

require "pakyow/error"

module Pakyow
  module Security
    class Error < Pakyow::Error
    end

    class InsecureRequest < Error
    end

    class InsecureRedirect < Error
      class_state :messages, default: {
        default: "Cannot redirect to remote, untrusted location `{location}'"
      }.freeze
    end
  end
end
