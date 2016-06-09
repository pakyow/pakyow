---
name: Configuration
desc: A full list of configuration options for Pakyow.
---

An app can be configured by defining a `configure` block for the environment in `app.rb`:

```ruby
configure :development do
  # put your development config here
end
```

Configuration defined in a `global` configure block will be available across all environments.

```ruby
configure :global do
  # put your global config here
end
```

Below you'll find a list of available config options (defaults in parenthesis).

## App Config

*app.auto_reload (development: true, staging: false, production: false)*  
When true, the app will be reloaded on every request.

*app.errors_in_browser (development: true, staging: false, production: false)*  
When true, app errors are displayed in the browser.

*app.root (./)*  
The location of the app's root directory.

*app.resources ({root}/public)*  
The location of the app's resources.

*app.src_dir ({root}/app/lib)*  
The location of the app's source code.

*app.default_environment (development)*  
The default environment to run the app in, when one isn't provided.

*app.default_action (index)*  
The default action to use for routing.

*app.ignore_routes (false)*  
When true, all routes are ignored.

*app.all_views_visible (true)*  
When true, all views are visible without a defined route.

*app.log_output (true)*  
Whether or not `$stdout` should write to the log.

*app.log (true)*  
Whether or not Pakyow should write to a log file.

*app.static (development: true, staging: false, production: false)*  
Whether or not pakyow should handle serving static files.

*app.path*  
The path to file containing the app definition (set at load time).

*app.loaded_envs*  
The environments the app is currently running in (set at run time).

## Server Config

*server.port (3000)*  
The port the app should run on.

*server.host (0.0.0.0)*  
The host the app should run on.

*server.handler*  
The handler to use (e.g. puma).

## Logger Config

*logger.level*  
What level of severity the logs care about (default: 'debug').

*logger.path ({root}/log)*  
The path to the logs.

*logger.filename (pakyow.log)*  
The name of the logfile.

*logger.sync (development: true, staging: false, production: false)*  
Whether or not the logs should be synced.

*logger.auto_flush (development: true, staging: false, production: false)*  
Whether or not the logs should be auto flushed.

*logger.colorize (development: true, staging: false, production: false)*  
Whether or not the logs should be colorized.

## Cookies Config

*cookies.path (/)*  
The path cookies should be created at.

*cookies.expiration (7 days)*  
When cookes should expire.

## Presenter Config

*presenter.view_stores*  
The configured view stores for the app.

*presenter.default_views (pakyow.html)*  
The default views for each view store.

*presenter.template_dirs (_templates)*  
The template directories for each view store.

*presenter.scope_attribute (data-scope)*  
The attribute used for scope definitions.

*presenter.prop_attribute (data-prop)*  
The attribute used for prop definitions.

*presenter.view_doc_class (StringDoc)*  
The doc class used to parse and render views.

## Mailer Config

*mailer.default_sender (Pakyow)*  
The default sender name.

*mailer.default_content_type (text/html; charset={encoding})*  
The default content type.

*mailer.delivery_method (sendmail)*  
The delivery method to use.

*mailer.delivery_options (enable_starttls_auto: false)*  
Other delivery options passed to Mail.

*mailer.encoding (UTF-8)*  
The encoding to use.

## Realtime Config

*realtime.redis ({ url: 'redis://localhost:6379' })*  
The Redis connection hash.

*realtime.redis_key (pw:channels)*  
The Redis key used to keep track of channel subscriptions.

*realtime.registry (development: SimpleRegistry, production: RedisRegistry)*  
The registry used to keep track of channel subscriptions.

## UI Config

*ui.registry (development: SimpleMutationRegistry, production: RedisMutationRegistry)*  
The registry used to keep track of registered mutations.
