# Calls an app route and returns a response, just like an HTTP request!
#
Pakyow::Realtime.handler :'call-route' do |message, session, response|
  path, qs = message['uri'].split('?')
  path_parts = path.split('/')

  if path =~ /^https?:\/\//
    path_parts << 'index' if path_parts.count == 3
  else
    path_parts << 'index' if path_parts.empty?
  end

  path_parts[-1] += '.json'
  uri = [path_parts.join('/'), qs].join('?')

  env = Rack::MockRequest.env_for(uri, method: message['method'])
  env['pakyow.socket'] = true
  env['pakyow.data'] = message['input']
  env['rack.session'] = session

  # TODO: in production we want to push the message to a queue and
  # let the next available app instance pick it up, rather than
  # the current instance to handle all traffic on this socket
  res = Pakyow.app.call(env)

  container = message['container']
  partial = message['partial']

  composer = Pakyow.app.presenter.composer

  if container
    body = composer.container(container.to_sym).includes(composer.partials).to_s
  elsif partial
    body = composer.partial(partial.to_sym).includes(composer.partials).to_s
  else
    body = res[2].body
  end

  response[:status]  = res[0]
  response[:headers] = res[1]
  response[:body]    = body
  response
end
