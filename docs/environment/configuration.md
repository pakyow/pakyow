---
name: Configuration
desc: Configuring Pakyow's environment.
---

Pakyow's environment can easily be configured at runtime:

```ruby
Pakyow.configure do
  config.server.port = 2001
end
```

You can also set config values for particular modes:

```ruby
Pakyow.configure do
  config.server.port = 2001
end

Pakyow.configure :production do
  config.server.port = 2002
end
```

In this case, running `pakyow server production` would start the environment on
port 2002. Starting Pakyow in a mode other than production would start the
environment on port 2001.

## Config Settings

Here's a comprehensive list of environment-level config options.

---

mode.default: the mode to start when not otherwise provided  
_default_: development

---

server.default: the application server to use by default  
_default_: puma

server.port: the port that the environment runs on  
_default_: 3000

server.host: the host that the environment runs on  
_default_: localhost

---

logger.enabled: whether or not logging is enabled  
_default_: true
logger.level: what level to log at  
_default_: :debug, :info (production)
logger.formatter: the formatter to use when logging  
_default_: {Logger::DevFormatter}, {Logger::LogfmtFormatter} (production)
logger.destinations: where logs are output to  
_default_: $stdout (when logger.enabled), /dev/null (for test environment or when logger is disabled)

---

normalizer.strict_path: whether or not request paths are normalized  
_default_: true
normalizer.strict_www: whether or not the www subdomain are normalized  
_default_: false
normalizer.require_www: whether or not to require www in the hostname  
_default_: true
