# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/ui/helpers"

require "pakyow/ui/behavior/recording"
require "pakyow/ui/behavior/rendering"
require "pakyow/ui/behavior/timeouts"

module Pakyow
  module UI
    class Framework < Pakyow::Framework(:ui)
      def boot
        app.class_eval do
          register_helper :passive, Helpers

          include Behavior::Recording
          include Behavior::Rendering
          include Behavior::Timeouts
        end
      end
    end
  end
end
