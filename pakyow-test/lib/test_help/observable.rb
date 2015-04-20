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
      def observing(scope, action, values)
        @observations ||= []
        @observations << {
          scope: scope,
          action: action,
          values: values
        }
      end

      def observed?(scope, action, values)
        return false if @observations.nil?
        @observations.each do |observation|
          next if observation[:scope] != scope
          next if observation[:action] != action

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
          return ObservableView.new(value, self.is_a?(ObservableView) ? presenter : self)
        end

        value
      end
    end
  end
end
