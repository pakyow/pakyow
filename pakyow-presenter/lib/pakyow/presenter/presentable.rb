module Pakyow
  module Presenter
    module Presentable
      attr_reader :presentables

      def initialize(*args)
        @presentables = self.class.presentables.dup
        super
      end

      def presentable(name, value = nil)
        args = {
          name: name,
          value: value
        }

        args[:block] = Proc.new if block_given?

        presentables.push(args).uniq!
      end

      module ClassMethods
        def presentable(name, value = nil)
          args = {
            name: name,
            value: value
          }

          args[:block] = Proc.new if block_given?

          presentables.push(args).uniq!
        end

        def presentables
          return @presentables if @presentables

          if frozen?
            []
          else
            @presentables = []
          end
        end
      end
    end
  end
end
