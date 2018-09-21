# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/mailer/behavior/config"
require "pakyow/mailer/helpers"

module Pakyow
  module Mailer
    class Framework < Pakyow::Framework(:mailer)
      def boot
        object.class_eval do
          include Behavior::Config

          register_helper :active, Helpers
        end
      end
    end
  end
end
