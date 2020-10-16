# frozen_string_literal: true

module Pakyow
  module Support
    module Pipeline
      # Creates a pipeline extension that can be included into a pipeline.
      #
      # @example
      #   module VerifyRequest
      #     extend Pakyow::Support::Pipeline::Extension
      #
      #     action :verify_request do
      #       ...
      #     end
      #   end
      #
      #   class Application
      #     include Pakyow::Support::Pipeline
      #
      #     use_pipeline VerifyRequest
      #
      #     ...
      #   end
      #
      module Extension
        def self.extended(base)
          base.include Pipeline
        end
      end
    end
  end
end
