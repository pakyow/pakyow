module Pakyow
  module Presenter
    module Presentable
      attr_reader :presentables

      def initialize(*args)
        @presentables = self.class.presentables.dup
        super
      end

      def presentable(*args)
        presentables.concat(args).uniq!
      end

      module ClassMethods
        def presentable(*args)
          presentables.concat(args).uniq!
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
