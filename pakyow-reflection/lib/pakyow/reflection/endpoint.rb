# frozen_string_literal: true

module Pakyow
  module Reflection
    class Endpoint
      attr_reader :view_path, :channel

      def initialize(view_path, channel: nil)
        @view_path, @channel = view_path, channel
      end
    end
  end
end
