module Pakyow
  module Presenter
    class Form

      attr_reader :form_view, :context

      def initialize(view, context)
        @form_view = view
        @context = context
      end

      def create(*binding_args, &block)
        bind_data(binding_args, block) do |routes, view|
          view.attrs.action = routes.path(:create, request_params) if routes
        end
      end

      def update(*binding_args, &block)
        bind_data(binding_args, block) do |routes, view|
          if routes
            route_params = request_params.merge(
              :"#{scoped_as}_id" => view.attrs.__send__('data-id').value
            )

            view.attrs.action = routes.path(:update, route_params)
          end

          view.prepend(
            View.new('<input type="hidden" name="_method" value="patch">')
          )
        end
      end

      private

      def bind_data(binding_args, block)
        bind(*binding_args) do |view, data|
          routes = Router.instance.group(scoped_as)

          yield(routes, view)

          return if block.nil?

          if block.arity == 1
            view.instance_exec(&block)
          else
            block.call(view, data)
          end
        end
      end

      def request_params
        context.request.params
      end

      def method_missing(method, *args, &block)
        if form_view.respond_to?(method)
          form_view.__send__(method, *args, &block)
        else
          super
        end
      end
    end
  end
end
