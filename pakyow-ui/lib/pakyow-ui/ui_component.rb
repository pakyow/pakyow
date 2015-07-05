require_relative 'ui_instructable'

module Pakyow
  module UI
    class UIComponent
      include Instructable

      attr_reader :name, :view, :qualifications

      def initialize(name, qualifications = {})
        super()
        @name = name
        @qualifications = qualifications
      end

      def nested_instruct_object(method, data, scope)
        UIComponent.new(name, qualifications)
      end

      def push(payload = nil)
        payload ||= { instruct: root.finalize }

        Pakyow.app.socket.push(
          payload,

          ChannelBuilder.build(
            component: name,
            qualifications: qualifications,
          )
        )
      end

      def scope(name)
        nested_instruct(:scope, name.to_s, name)
      end

      %i[append prepend].each do |method|
        define_method method do |value|
          instruct(method, value)
          push
        end
      end
    end
  end
end
