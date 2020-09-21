# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/message_verifier"

module Pakyow
  module Behavior
    module Verifier
      extend Support::Extension

      class_methods do
        attr_reader :verifier
      end

      apply_extension do
        before :boot do
          config.secrets.reject! do |secret|
            secret.nil? || secret.empty?
          end

          if config.secrets.any?
            @verifier = Support::MessageVerifier.new(config.secrets[0])
          else
            raise "Pakyow will not boot without a secret configured in `Pakyow.config.secrets`"
          end
        end
      end
    end
  end
end
