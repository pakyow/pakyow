# Calls a route and returns a response, just like an HTTP request!
#
Pakyow::Realtime.handler :'call-route' do |message, connection, response|
  logger = Pakyow::Logger::RequestLogger.new(:sock, id: connection.key[0..7])

  uri = URI.parse(message['uri'])
  env = Rack::MockRequest::DEFAULT_ENV.dup

  env[Rack::RACK_URL_SCHEME] = uri.scheme
  env[Rack::PATH_INFO] = uri.path
  env[Rack::QUERY_STRING] = uri.query
  env[Rack::REQUEST_METHOD] = message['method'].upcase

  env['REQUEST_URI'] = message['uri']
  env['REMOTE_ADDR'] = connection.env['REMOTE_ADDR']
  env['HTTP_X_FORWARDED_FOR'] = connection.env['HTTP_X_FORWARDED_FOR']

  env['rack.logger'] = logger
  env['rack.session'] = connection.env['rack.session']
  env['pakyow.socket'] = true
  env['pakyow.data'] = message['input']

  logger.prologue(env)
  context = Pakyow::CallContext.new(env)
  context.process
  res = context.finish
  logger.epilogue(res)

  container = message['container']
  partial = message['partial']

  composer = context.presenter.composer

  if container
    body = composer.container(container.to_sym).includes(composer.partials).to_s
  elsif partial
    body = composer.partial(partial.to_sym).includes(composer.partials).to_s
  else
    body = res[2].body
  end

  response[:status]  = res[0]
  response[:headers] = res[1]
  response[:body]    = body.is_a?(StringIO) ? body.read : body
  response
end
