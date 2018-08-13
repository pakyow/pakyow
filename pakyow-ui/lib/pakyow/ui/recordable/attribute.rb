# frozen_string_literal: true

require "json"

require "pakyow/ui/recordable/helpers/client_remapping"

module Pakyow
  module UI
    module Recordable
      class Attribute
        include Helpers::ClientRemapping

        def initialize(attribute)
          @attribute = attribute
          @calls = []
        end

        %i([] []= << delete clear add).each do |method_name|
          define_method method_name do |*args|
            @attribute.send(method_name, *args).tap do
              @calls << [remap_for_client(method_name), args, [], []]
            end
          end
        end

        def to_json(*)
          @calls.to_json
        end
      end
    end
  end
end
