# frozen_string_literal: true

require "json"

require "pakyow/ui/recordable/attribute"
require "pakyow/ui/recordable/helpers/client_remapping"

module Pakyow
  module UI
    module Recordable
      # @api private
      class Attributes < Pakyow::Presenter::Attributes
        include Helpers::ClientRemapping

        %i([] []=).each do |method_name|
          define_method method_name do |*args|
            result = super(*args)

            result = case method_name
            when :[]
              Attribute.new(result)
            else
              result
            end

            subsequent = if result.is_a?(Attribute)
              result
            else
              []
            end

            @calls << [remap_for_client(method_name), args, [], subsequent]

            result
          end
        end

        def to_json(*)
          @calls.to_json
        end

        class << self
          def from_attributes(attributes)
            instance = new(attributes.instance_variable_get(:@attributes))
            instance.instance_variable_set(:@calls, [])
            instance
          end
        end
      end
    end
  end
end
