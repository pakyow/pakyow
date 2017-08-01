module Pakyow
  module Presenter
    module Presentable
      attr_reader :presentables

      def initialize(*args)
        @presentables = self.class.presentables.dup
        super
      end

      def presentable(name, default_value = default_omitted = true)
        raise ArgumentError, "name must a symbol" unless name.is_a?(Symbol)

        args = {}

        if default_omitted && !block_given?
          args[:method_name] = name
        else
          args[:value] = default_value unless default_omitted
          args[:value] = yield if args[:value].nil? && block_given?
        end

        presentables[name] = args
      end

      module ClassMethods
        def presentable(name, default_value = default_omitted = true)
          raise ArgumentError, "name must a symbol" unless name.is_a?(Symbol)

          args = {}

          if default_omitted && !block_given?
            args[:method_name] = name
          else
            args[:default_value] = default_value unless default_omitted
            args[:block] = Proc.new if block_given?
          end

          presentables[name] = args
        end

        def presentables
          return @presentables if @presentables

          if frozen?
            {}
          else
            @presentables = {}
          end
        end
      end
    end
  end
end
