---
name: Production
desc: Using realtime channels in production.
---

Pakyow assumes you'll be using Redis when running a realtime application in a
production environment. This is necessary because of the fact that each
application instance manages its own WebSocket connections. When a message is
pushed from one instance, the other instances need to know to send the message
to their connections as well. This is handled with Redis Pub/Sub.

The `realtime.redis` config option is defines the Redis connection information.
By default it's set to `{ url: 'redis://localhost:6379' }`.  Feel free to change
it to match your environment (see [Configuration Options](/docs/config)).

All subscription information is stored under the `pw:channels` key by default.
In the rare case this conflicts with another key, set the `realtime.redis_key`
config option accordingly.
