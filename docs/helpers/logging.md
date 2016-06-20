---
name: Logging
desc: Writing to the logs.
---

Writing to the logs during the request / response lifecylcle can
be done through the `logger` helper:

```ruby
logger.info 'hello'
```

The log message will be decorated with several additional values:

- elapsed time
- request type (e.g. `http`, `sock`)
- unique request id

This is how the above log message would be displayed in development:

```
1.97ms http.c730cb72 | hello
```

The following methods are available on the logger:

- debug
- info
- warn
- error
- fatal
- <<
- add
- log
- unknown

Several [configuration options](/docs/config) are available within the logger context.

### Global Logger

A global logger object is available through `Pakyow.logger` for logging
outside of the normal request / response lifecycle.

```ruby
Pakyow.logger
=> #<Logger:0x007ff8257b0f78>
```
