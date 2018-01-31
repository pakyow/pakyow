# frozen_string_literal: true

require "pakyow/support/pipelined"

module Pakyow
  module Security
    module CSRF
      extend Support::Pipelined::Pipeline

      action :verify_same_origin
      action :verify_authenticity_token

      def verify_same_origin
        config.csrf.protection[:origin].call(@__connection)
      end

      def verify_authenticity_token
        config.csrf.protection[:authenticity].call(@__connection)
      end
    end
  end
end
