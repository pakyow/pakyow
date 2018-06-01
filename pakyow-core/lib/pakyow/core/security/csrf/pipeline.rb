# frozen_string_literal: true

require "pakyow/support/pipelined"

module Pakyow
  module Security
    module CSRF
      extend Support::Pipelined::Pipeline

      action :verify_same_origin
      action :verify_authenticity_token

      def verify_same_origin
        config.security.csrf.protection[:origin].call(@connection)
      end

      def verify_authenticity_token
        config.security.csrf.protection[:authenticity].call(@connection)
      end
    end
  end
end
