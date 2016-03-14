# 0.11.0

  * Gracefully shuts down WebSocket when something bad happens
  * Fixes a bug calling the root route over a WebSocket
  * Fixes a bug causing join events to be fired before the connection is registered
  * Fixes a bug causing session to not be serialized in redis
  * Fixes a bug causing redis subscriptions to never unsubscribe
  * Properly disconnects from redis as necessary to avoid eating up connections

# 0.10.2 / 2015-11-15

  * Adds ability to return only a partial in call-route response
  * Fixes several bugs with the redis registry / subscriptions
  * Fixes a bug causing qualifications to not match when using redis
  * Bumps concurrent-ruby version to 1.0

# 0.10.0 / 2015-10-19

  * Initial release
