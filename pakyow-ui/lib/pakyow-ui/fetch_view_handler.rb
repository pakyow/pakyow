Pakyow::Realtime::MessageHandler.register :'fetch-view' do |message, session, response|
  env = Rack::MockRequest.env_for(message['uri'])
  env['rack.session'] = session

  app = Pakyow.app.dup

  def app.view
    Pakyow::Presenter::NoOpView.new(Pakyow::Presenter::ViewContext.new(@presenter.view, self), self)
  end

  app_response = app.process(env)

  body = ''
  lookup = message['lookup']
  view = app.presenter.view

  if channel = lookup['channel']
    unqualified_channel = channel.split('::')[0]

    view_for_channel = view.composed.doc.channel(unqualified_channel)
    view_for_channel.set_attribute(:'data-channel', channel)

    body = view_for_channel.to_html
  else
    lookup.each_pair do |key, value|
      next if key == 'version'
      view = view.send(key.to_sym, value.to_sym)
    end

    if view.is_a?(Pakyow::Presenter::ViewVersion)
      body = view.use(lookup['version'] || :default).to_html
    else
      body = view.to_html
    end
  end

  response[:status]  = app_response[0]
  response[:headers] = app_response[1]
  response[:body] = body
  response
end

module Pakyow
  module Presenter
    class NoOpView
      include Helpers
      VIEW_CLASSES = [ViewContext]

      # The arities of misc view methods that switch the behavior from
      # instance_exec to yield.
      #
      EXEC_ARITIES = { with: 0, for: 1, for_with_index: 2, repeat: 1,
        repeat_with_index: 2, bind: 1, bind_with_index: 2, apply: 1 }

      def initialize(view, context)
        @view = view
        @context = context
      end

      def is_a?(klass)
        @view.is_a?(klass)
      end

      # View methods that should be a no-op
      #
      %i[bind bind_with_index apply].each do |method|
        define_method(method) do |data, **kargs, &block|
          self
        end
      end

      def mutate(mutator, with: nil, params: nil, data: nil)
        MockMutationEval.new(mutator, with, self)
      end

      # Pass these through, handling the return value.
      #
      def method_missing(method, *args, &block)
        ret = @view.send(method, *args, &wrap(method, &block))
        handle_return_value(ret)
      end

      private

      def view?(obj)
        VIEW_CLASSES.include?(obj.class)
      end

      # Returns a new context for returned views, or the return value.
      #
      def handle_return_value(value)
        if view?(value)
          return NoOpView.new(value, @context)
        end

        value
      end

      # Wrap the block, substituting the view with the current view context.
      #
      def wrap(method, &block)
        return if block.nil?

        Proc.new do |*args|
          ctx = args.map! { |arg|
            view?(arg) ? NoOpView.new(arg, @context) : arg
          }.find { |arg| arg.is_a?(ViewContext) }

          case block.arity
          when EXEC_ARITIES[method]
            # Rejecting ViewContext handles the edge cases around the order of
            # arguments from view methods (since view is not present in some
            # situations and when it is present, is always the first arg).
            ctx.instance_exec(*args.reject { |arg|
              arg.is_a?(ViewContext)
            }, &block)
          else
            block.call(*args)
          end
        end
      end
    end
  end
end

class MockMutationEval
  def initialize(mutation_name, relation_name, view)
    @mutation_name = mutation_name
    @relation_name = relation_name
    @view = view
  end

  #NOTE we don't care about qualifiers here since we're just getting
  # the proper view template; not actually setting it up with data
  def subscribe(*args)
    channel = Pakyow::UI::ChannelBuilder.build(
      scope: @view.scoped_as,
      mutation: @mutation_name,
    )

    @view.attrs.send(:'data-channel=', channel)
  end
end
