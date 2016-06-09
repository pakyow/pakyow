---
name: Message Handlers
desc: Handling custom messages over realtime channels.
---

Any incoming message from a client is routed to a message handler. The handler
can then perform some action and send back a response message. For example, the
[call route](/realtime/routing) handler that ships with Pakyow Realtime is
implemented as a handler ([source](https://github.com/pakyow/pakyow/blob/master/pakyow-realtime/lib/pakyow-realtime/message_handlers/call_route.rb)).

Messages must be sent in the following format:

```javascript
{
  id: 'unique-message-id',
  action: 'some-action'
}
```

The message can contain any number of custom fields required by the handler.

Handlers are implemented as blocks that accept a message and return a response.
The connection's session and a default response object are also passed to the
message handler block. Here's a completely valid handler that performs no action:

```ruby
Pakyow::Realtime::MessageHandler.register :'some-action' do |message, session, response|
  response
end
```
