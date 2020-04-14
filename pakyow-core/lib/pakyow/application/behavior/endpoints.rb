# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../endpoints"

module Pakyow
  class Application
    module Behavior
      module Endpoints
        extend Support::Extension

        apply_extension do
          on "initialize" do
            @endpoints = ::Pakyow::Endpoints.new(prefix: mount_path)
          end
        end

        # Instance of {Endpoints} for path building.
        #
        attr_reader :endpoints
      end
    end
  end
end
