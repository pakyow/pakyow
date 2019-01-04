# frozen_string_literal: true

require "json"

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Behavior
      module RequestParsing
        extend Support::Extension

        apply_extension do
          class_state :request_parsers, default: {}

          before :configure do
            Pakyow.parse_request "application/json" do |body|
              JSON.parse(body)
            end
          end
        end

        class_methods do
          def parse_request(type, &block)
            @request_parsers[type] = block
          end
        end
      end
    end
  end
end
