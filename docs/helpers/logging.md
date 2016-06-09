---
name: Logging
desc: Writing to a log file.
---

Write to the log using the static Logger class:

```ruby
Pakyow.logger.write 'hello log'
```

You can also specify a severity:

```ruby
Pakyow.logger.write 'this is just a warning', :warn
```

The logger can be [configured](/docs/config) to ignore statements below a particular severity.
