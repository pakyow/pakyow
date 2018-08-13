# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/mailer/behavior/config"
require "pakyow/mailer/helpers"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        app.class_eval do
          include Behavior::Config

          subclass :Controller do
            include Helpers
          end
        end
      end
    end
  end
end
