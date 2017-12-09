# frozen_string_literal: true

module Pakyow
  module Realtime
    class Channel
      class << self
        def parse(qualified_channel)
          Channel.new(*qualified_channel.split("::", 2))
        end
      end

      attr_reader :name, :qualifier

      def initialize(channel_name, qualifier = nil)
        @name, @qualifier = channel_name, qualifier
      end

      def to_s
        [@name, @qualifier].join("::")
      end
    end
  end
end
