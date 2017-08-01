require "sequel"

require "pakyow/support/hookable"

module Pakyow
  module Data
    class Model
      include Support::Hookable
      known_events :mutated

      extend Support::DeepFreeze
      unfreezable :object

      class << self
        attr_reader :name

        def make(name, state: nil, &block)
          klass = const_for_data_named(Class.new(self), name)

          klass.class_eval do
            @name = name
            class_eval(&block) if block
          end

          klass
        end

        def const_for_data_named(data_class, name)
          return data_class if name.nil?

          # convert snake case to camel case
          class_name = "#{name.to_s.split('_').map(&:capitalize).join}Data"

          if Object.const_defined?(class_name)
            data_class
          else
            Object.const_set(class_name, data_class)
          end
        end

        def object(object = nil)
          return @object unless object
          @object = object
        end

        # TODO: support multiple calls to `commands` and an `command` method (that optionally accepts a block)
        def commands(*commands)
          @commands = commands
        end

        def command?(name)
          @commands.include?(name)
        end
      end

      def method_missing(name, *args)
        @call = [name, args]

        if self.class.command?(@call[0])
          call # call commands immediately
        else
          self
        end
      end

      def call
        if self.class.command?(@call[0])
          @mutation = perform
          call_hooks(:after, :mutated); @mutation
        else
          perform
        end
      end

      protected

      def perform
        self.class.object.send(@call[0], *@call[1])
      end
    end
    end
end

Pakyow::App.stateful :model, Pakyow::Data::Model

Pakyow::Data::Model.after :mutated do
  # TODO: we'd hook in here to know when to react to mutations in places like pakyow/ui
end

module Pakyow
  module Helpers
    def model
      controller.app.state[:model]
    end
  end
end

module Pakyow
  module Support
    class State
      # TODO: this should be part of the standard api; would require there to be a name (which is fine)
      # and probably define the methods rather than rely on method missing
      def method_missing(name)
        if instance = instances.find { |instance|
          instance.name == name
        }

          instance.new
        else
          # FIXME: getting an undefined method error is odd here... should we call super or?
          super
        end
      end
    end
  end
end
