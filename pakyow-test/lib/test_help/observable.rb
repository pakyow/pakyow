module Pakyow
  module TestHelp
    module Observable
      #TODO a version of this exists in ViewContext; consider drying it up
      VIEW_CLASSES = [
        Pakyow::Presenter::View,
        Pakyow::Presenter::ViewCollection,
        Pakyow::Presenter::Partial,
        Pakyow::Presenter::Template,
        Pakyow::Presenter::Container,
        Pakyow::Presenter::ViewComposer
      ]

      def method_missing(name, *args, &block)
        handle_value(observable.send(name, *args, &block))
      end

      #TODO likely need to handle nested observations
      def observing(scope, action, traversal, values)
        @observations ||= []
        @observations << {
          scope: scope,
          action: action,
          traversal: traversal,
          values: values
        }
      end

      def observed?(scope, action, traversal, values)
        return false if @observations.nil?
        @observations.each do |observation|
          next if observation[:scope] != scope
          next if observation[:action] != action
          next if observation[:traversal] != traversal

          values.each_pair do |k, v|
            next if observation[:values][k] != v
          end

          return true
        end

        return false
      end

      private

      def handle_value(value)
        if VIEW_CLASSES.include?(value.class)
          traversal = []
          if self.is_a?(ObservableView)
            parent = presenter
            if view.is_a?(Pakyow::Presenter::View) || view.is_a?(Pakyow::Presenter::ViewCollection)
              traversal = @traversal.dup
              traversal << value.scoped_as
            end
          else
            parent = self
          end

          if value.is_a?(Pakyow::Presenter::ViewCollection)
            value.instance_variable_get(:@views).map! { |collected_view|
              ObservableView.new(collected_view, parent, traversal)
            }
          end

          return ObservableView.new(value, parent, traversal)
        end

        value
      end
    end
  end
end
