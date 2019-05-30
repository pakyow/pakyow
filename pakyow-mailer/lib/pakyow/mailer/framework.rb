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

          mail_renderer = Class.new(isolated(:Renderer)) do
            # Override so we don't trigger any hooks.
            #
            def perform(output = String.new)
              @presenter.to_html(output)
            end
          end

          # Delete the create_template_nodes build step since we don't want to mail templates.
          #
          mail_renderer.__build_fns.delete_if { |fn|
            fn.source_location[0].end_with?("create_template_nodes.rb")
          }

          const_set(:MailRenderer, mail_renderer)
        end
      end
    end
  end
end
