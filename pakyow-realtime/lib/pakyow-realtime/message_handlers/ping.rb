Pakyow::Realtime::MessageHandler.register :ping do |message, session, response|
  response[:status] = 200
  response[:headers] = {}
  response[:body] = 'pong'
  response
end
