require_relative 'ui_instructable'

module Pakyow
  module UI
    # An object for interacting with components rendered in a browser. Custom
    # messages can be pushed and will be handled by the event listener defined
    # on the client-side component.
    #
    # It's also possible to perform view transformations in realtime. Components
    # implement a subset of transformations, including `scope` and `append`.
    # This allows for finer control over particular components, completely
    # bypassing mutables and mutators.
    #
    # @api public
    class UIComponent
      include Instructable

      attr_reader :name, :view, :qualifications

      # Intended to be created through the `ui.component` helper.
      #
      # @api private
      def initialize(name, qualifications = {})
        super()
        @name = name
        @qualifications = qualifications
      end

      # Pushes a message to the component.
      #
      # @api public
      def push(payload = nil)
        payload ||= { instruct: (root || self).finalize }

        Pakyow.app.socket.push(
          payload,

          ChannelBuilder.build(
            component: name,
            qualifications: qualifications
          )
        )
      end

      # Narrows the scope of component instructions.
      #
      # @api public
      def scope(name)
        nested_instruct(:scope, name.to_s, name)
      end

      # Other supported transformation methods.
      #
      # @api public
      %i(append prepend).each do |method|
        define_method method do |value|
          instruct(method, value)
          push
        end
      end

      # @api private
      def nested_instruct_object(_method, _data, _scope)
        UIComponent.new(name, qualifications)
      end
    end
  end
end
