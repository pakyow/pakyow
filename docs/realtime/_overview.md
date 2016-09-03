---
name: Realtime Channels
desc: Building realtime applications using channels.
---

The 0.10 release introduced realtime channels to Pakyow. To put it simply,
channels provide the ability to communicate with an application in realtime over
a WebSocket. Channels can be used for realtime communication between client and
server, or even between instances of an application.

Each client can be subscribed to one or more channels. The application managing
the channels is the sender, while subscribed clients are receivers. Messages can
be sent by the application and will be received by all subscribed clients.

Clients can also pass messages to the application. The application handles these
incoming messages with *handlers*, which can be extended. Handlers can do many
things, including routing messages to REST endpoints. With Pakyow Realtime, an
application's routes can be called over a WebSocket just as easily as HTTP.

## Channel Subscriptions

From within a route, the connected client socket can be accessed via the
`socket` helper. You can then be subscribe the client socket to a channel by
calling `subscribe`.

```ruby
socket.subscribe(:chan1)
```

You can also subscribe the client socket to multiple channels at once:

```ruby
socket.subscribe(:chan1, :chan2)
```

To unsubscribe a client socket from one or more channels, use `unsubscribe`.

```ruby
socket.unsubscribe(:chan2)
```

That's all there is to it!

## Pushing Messages

To send a message to connections on one or more channels, use `push`.

```ruby
socket.push({ foo: 'bar' }, :chan1)
```

The data (a hash in our case) will be serialized as JSON and pushed to all
connections who are subscribed to `chan1`.

## Connecting

Establishing a connection is easy. When an HTTP request is made to establish a
WebSocket connection, Pakyow will hijack the request, perform the handshake, and
create a new thread where the WebSocket will spend its entire lifetime.

Each WebSocket connection has a unique connection id. This is an important
security feature of Pakyow Realtime. You can read more about this feature later
on in this guide. For now, just know that the connection id is important if you
expect to receive any messages on subscribed channels.

When rendering a view, the connection id is automatically added to the body tag
in the `data-socket-connection-id` attribute. With a bit of JavaScript, we can
establish a WebSocket connection with the server:

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

window.socket = new WebSocket(wsUrl);

window.socket.onopen = function (event) {
  console.log('socket opened');
};

window.socket.onmessage = function (evt) {
  console.log('socket message');
  console.log(JSON.parse(evt.data));
};
```

Now any messages received by the client will be logged in the browser console.

If you aren't using a browser to establish a WebSocket, you'll have to obtain
the connection id in some other way (such as an API call to the application).
It's available through the `socket_connection_id` helper method.

## Connection ID &amp; Security

As mentioned above, the connection id is an important security feature of Pakyow
Realtime. The connection id is used to determine the channels that each connection
should be subscribed to. All subscriptions are managed using a *socket digest*,
which is generated from a *socket key* and *connection id*.

The connection id is made available to the client, while the socket key is
either 1) stored in the session (when connecting from a browser client) or 2)
provided by the client along with the connection id. If either piece of
information is incorrect, the socket digest will not match and the connection
will not receive its intended messages.

Each connection id and socket key lasts for the duration of a connection. This
means that each time you refresh a browser, a new connection id and key is
generated while the old ones are invalidated.

## Example Realtime Application

You can find a maintained realtime application
[here](https://github.com/bryanp/pakyow-example-realtime). This example shows
how messages can be pushed to subscribed clients, along with sample code for
calling routes over a WebSocket.
