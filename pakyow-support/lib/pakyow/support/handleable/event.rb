# frozen_string_literal: true

require "delegate"

require "pakyow/support/pipeline/object"

module Pakyow
  module Support
    module Handleable
      class Event < SimpleDelegator
        include Pipeline::Object

        def object
          __getobj__
        end
      end
    end
  end
end
