# pakyow-realtime

Brings realtime capabilities to Pakyow by creating a pub/sub
connection between client and server using WebSockets.

## Overview

Clients can be subscribed to channels. Realtime keeps track of what channels a
client has been subscribed to and tracks subscriptions across requests. Routes
can push messages down channels to one or more subscribed clients through an
established WebSocket.

WebSockets are established by hijacking an HTTP request. Once hijacked, the
WebSocket is forked into an async object via the highly performant [Concurrent
Ruby](https://github.com/ruby-concurrency/concurrent-ruby) library. This
approach allows each app instance to manage its own WebSockets while still
serving normal requests.

In addition to pushing messages from the server to the client, the client can
send messages to the server. For example, out of the box Realtime supports
calling routes over a WebSocket, with the response being pushed down once
processing is complete.

## Establishing a WebSocket connection to the server.

Using the native Javascript `WebSocket` support in modern browsers, simply open
a connection to your app. You'll need to include the connection id associated
with your client, which tells Realtime what channels the connection should
listen to. This connection id is automatically set on the `body` tag in a
rendered view.

Here's some example Javascript code that establishes a WebSocket connection:

```javascript
var wsUrl = '';

var host = window.location.hostname;
var port = window.location.port;

if (window.location.protocol === 'http:') {
  wsUrl += 'ws://';
} else if (window.location.protocol === 'https:') {
  wsUrl += 'wss://';
}

wsUrl += host;

if (port) {
  wsUrl += ':' + port;
}

var conn = document.getElementsByTagName('body')[0].getAttribute('data-socket-connection-id');
wsUrl += '/?socket_connection_id=' + conn;

console.log('Opening connection with id: ' + conn);
window.socket = new WebSocket(wsUrl);

window.socket.onopen = function (event) {
  console.log('Socket opened.');
};
```

A full example is available in the [example app](https://github.com/bryanp/pakyow-example-realtime).

### Security

The connection id is an important security feature of Realtime. Channel
subscriptions are managed with a socket digest, generated from a key and
connection id. The key is stored in the session object for a single client. If a
socket is established with an incorrect connection id for the current client,
the connection won't receive messages directed at that client (although the
connection will appear to have been properly established) because the digest
generated will also be incorrect.

## Subscribing a client to a channel.

From a route, simply call the `subscribe` method on the socket:

```ruby
socket.subscribe(:chan1)
```

To unsubscribe, call `unsubscribe`:

```ruby
socket.unsubscribe(:chan1)
```

## Pushing messages through a channel to one or more clients.

To push a message down a channel, call `push` from a route:

```ruby
socket.push({ foo: 'bar' }, :chan1)
```

The first argument is the message and the second argument is a single channel or
list of channels to push the message through. Each client subscribed to the
channel will receive the message as a JSON object.

## Calling routes from the client.

Realtime also provides a mechanism for round trip client -> server -> client
communication. Bundled with the library is a handler for calling routes through
a WebSocket. An example of this is included in the example app.

## Running in production.

Redis is leveraged in production to handle:

1. Tracking what clients are subscribed to what channels.
2. Communicating between WebSocket connections contained on various app
instances. Redis must be used to scale beyond a single app instance.

The Redis registry will automatically be used when running in a `production`
environment. But, in case you ever need to configure manually, add the following
code to the appropriate `configure` block in `app/setup.rb`:

```ruby
realtime.registry = Pakyow::Realtime::RedisRegistry
```

To configure the Redis connection itself, configure like this:

```ruby
realtime.redis = { url: 'redis://localhost:6379' }
```

## Defining custom message handlers.

Custom handlers can be defined for letting clients tell the server to do specific
things. Check out the bundled [`call_route` handler](https://github.com/pakyow/pakyow/blob/master/pakyow-realtime/lib/pakyow-realtime/message_handlers/call_route.rb), with a usage example in the
[example app](https://github.com/bryanp/pakyow-example-realtime).

# Download

The latest version of Pakyow Realtime can be installed with RubyGems:

```
gem install pakyow-realtime
```

Source code can be downloaded as part of the Pakyow project on Github:

- https://github.com/pakyow/pakyow/tree/master/pakyow-realtime

# License

Pakyow Realtime is free and open-source under the [LGPLv3 license](https://choosealicense.com/licenses/lgpl-3.0/).

# Support

Documentation is available here:

- http://pakyow.org/docs/realtime

Found a bug? Tell us about it here:

- https://github.com/pakyow/pakyow/issues

We'd love to have you in the community:

- http://pakyow.org/get-involved
