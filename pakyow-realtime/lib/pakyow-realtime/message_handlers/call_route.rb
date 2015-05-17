Pakyow::Realtime::MessageHandler.register :call_route do |message, session, response|
  path, qs = message['uri'].split('?')
  path_parts = path.split('/')
  path_parts[-1] += '.json'
  uri = [path_parts.join('/'), qs].join('?')

  env = Rack::MockRequest.env_for(uri, method: message['method'])
  env['pakyow.socket'] = true
  env['pakyow.data'] = message['input']
  env['rack.session'] = session

  #TODO in production we want to push the message to a queue and
  # let the next available app instance pick it up, rather than
  # the current instance to handle all traffic on this socket
  app_response = Pakyow.app.call(env)

  response[:status] = app_response[0]
  response[:headers] = app_response[1]
  response[:body] = app_response[2].body
  response
end
