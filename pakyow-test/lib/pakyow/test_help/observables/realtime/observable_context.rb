# frozen_string_literal: true

module Pakyow
  module TestHelp
    module Realtime
      class ObservableContext
        def initialize(context)
          @context = Pakyow::Realtime::Context.new(context)
          @pushes = {}
        end

        def method_missing(method, *args, &block)
          @context.send(method, *args, &block)
        end

        def push(msg, *channels)
          channels.each do |channel|
            (@pushes[channel.to_sym] ||= []) << msg
          end
        end

        def pushed?(message = nil, to: nil)
          if to.nil? && message.nil?
            !@pushes.empty?
          elsif to.nil? && message
            @pushes.values.flatten.include?(message)
          elsif message.nil? && to
            @pushes.key?(to.to_sym)
          else
            @pushes.fetch(to.to_sym).include?(message)
          end
        end
      end
    end
  end
end
