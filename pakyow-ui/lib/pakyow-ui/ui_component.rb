require_relative 'ui_instructable'

module Pakyow
  module UI
    class UIComponent
      include Instructable

      attr_reader :name, :view

      def initialize(name)
        super()
        @name = name
      end

      def nested_instruct_object(method, data, scope)
        UIComponent.new(@name)
      end

      def push
        #TODO make it work with qualifiers
        Pakyow.app.socket.push(
          { instruct: finalize },

          ChannelBuilder.build(
            component: name,
          )
        )
      end

      def scope(name)
        nested_instruct(:scope, name.to_s, name)
      end

      def append(data)
        instruct(:append, data)
      end

      def prepend(data)
        instruct(:prepend, data)
        push
      end
    end
  end
end
