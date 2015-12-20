require_relative 'no_op_view'

# Makes it possible to fetch a particular part of a view for a path. Calls a
# route with all view actions becoming no-ops. Then a query is run against the
# final view, pulling out the part that was requested.
#
# Expects the following in the message:
#
# - uri: the route to call
# - lookup: the view query
#
# Lookup currently supports the following keys:
#
# - channel
# - version
# - container
# - partial
# - scope
# - prop
#
Pakyow::Realtime.handler :'fetch-view' do |message, session, response|
  env = Rack::MockRequest.env_for(message['uri'])
  env['rack.session'] = session

  context = Pakyow::CallContext.new(env)

  def context.view
    Pakyow::Presenter::NoOpView.new(
      Pakyow::Presenter::ViewContext.new(@presenter.view, self),
      self
    )
  end

  app_response = context.process.finish

  body = ''
  lookup = message['lookup']
  view = context.presenter.view

  channel = lookup['channel']

  if channel
    unqualified_channel = channel.split('::')[0]
    view_for_channel = view.composed.doc.channel(unqualified_channel)

    if view_for_channel
      view_for_channel.set_attribute(:'data-channel', channel)
      body = view_for_channel.to_html
    end
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
