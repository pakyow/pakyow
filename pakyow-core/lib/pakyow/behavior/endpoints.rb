# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/endpoints"

module Pakyow
  module Behavior
    module Endpoints
      extend Support::Extension

      apply_extension do
        after :initialize do
          load_endpoints
        end
      end

      prepend_methods do
        def initialize(*)
          @endpoints = ::Pakyow::Endpoints.new

          super
        end
      end

      # Instance of {Endpoints} for path building.
      #
      attr_reader :endpoints

      private

      def load_endpoints
        state.each_with_object(@endpoints) { |(_, state_object), endpoints|
          state_object.instances.each do |state_instance|
            endpoints.load(state_instance)
          end
        }
      end
    end
  end
end
