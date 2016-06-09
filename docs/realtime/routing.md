---
name: Calling Routes
desc: Calling routes over a realtime connection.
---

Pakyow Realtime ships with a message handler that makes it possible to call
routes over a WebSocket. From the perspective of the application, calling a
route over a WebSocket is identical to handling an HTTP request.

To call a route, send a message like this through the WebSocket:

```javascript
{
  id: 'unique-message-id',
  action: 'call-route',
  uri: '/some-path',
  method: 'get'
}
```

The application will respond with a response that resembles an HTTP response.

```javascript
{
  id: 'unique-message-id',
  status: 200,
  headers: {
    ...
  },
  body: {
    ...
  }
}
```

Keep in mind that responses are asynchronous, so you must implement some way of
handling callbacks based on message id. We make this easy with
[Ring](https://github.com/pakyow/ring).
