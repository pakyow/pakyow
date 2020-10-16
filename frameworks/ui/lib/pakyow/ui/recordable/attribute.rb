# frozen_string_literal: true

require "delegate"
require "json"

require "pakyow/ui/recordable/helpers/client_remapping"

module Pakyow
  module UI
    module Recordable
      # @api private
      class Attribute < SimpleDelegator
        include Helpers::ClientRemapping

        def initialize(attribute)
          __setobj__(attribute)
          @calls = []
        end

        %i([] []= << delete clear add).each do |method_name|
          define_method method_name do |*args|
            result = super(*args)
            @calls << [remap_for_client(method_name), args, [], []]
            result
          end
        end

        def to_json(*)
          @calls.to_json
        end

        # Fixes an issue using pp inside a delegator.
        #
        def pp(*args)
          Kernel.pp(*args)
        end
      end
    end
  end
end
