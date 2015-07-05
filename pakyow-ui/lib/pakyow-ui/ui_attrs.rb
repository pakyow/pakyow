require_relative 'ui_instructable'

module Pakyow
  module UI
    class UIAttrs
      include Instructable

      def nested_instruct_object(method, data, scope)
        UIAttrs.new
      end

      def method_missing(method, value)
        nested_instruct(method, value)
      end

      def class
        method_missing(:class, nil)
      end

      def id
        method_missing(:id, nil)
      end
    end
  end
end
