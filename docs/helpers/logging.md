---
name: Logging
desc: Writing to the logs.
---

Use the `logger` helper to write to the logs during the request / response
lifecycle. Log messages will be decorated with several additional values:

- elapsed time
- request type (e.g. `http`, `sock`)
- unique request id

Here's an example using the default development logger:

```ruby
logger.info 'hello'
=> 1.97ms http.c730cb72 | hello
```

Pakyow's logger wraps an instance of Ruby's Logger object. Each log message has
an associated level that indicates its level of importance. Only messages that
are at the configured level or higher will be logged.

Here is a list of log levels:

- Unknown: An uknown message (these are always logged).
- Fatal: An unhandleable error that causes the app to crash.
- Error: A handleable error; typically results in a 500 status code.
- Warning: A warning (e.g. potentially unexpected behavior).
- Info: Generic information about app operation.
- Debug: Low-level information useful to app developers.

*Above log level documentation based heavily on [ruby-doc](http://ruby-doc.org/).*

Messages can be logged at a particular level with the cooresponding method:

```ruby
logger.unknown
logger.fatal
logger.error
logger.warning
logger.info
logger.debug
```

Log a message without any formatting:

```ruby
logger << '...'
```

Log a message at a particular level:

```ruby
logger.log :info, '...'
```

### Configuration

Several [configuration options](/docs/config) are available within the logger context.

### Global Logger

A global logger object is available through `Pakyow.logger` for logging
outside of the normal request / response lifecycle.

```ruby
Pakyow.logger
=> #<Logger:0x007ff8257b0f78>
```
