# 0.10.3

  * Adds a `configure` hook for evaluating code before/after configuring app
  * The `Pakyow::App.define` method now returns the defined app
  * Explicitly requires `pakyow-support` so core works on its own
  * Adds a convenience method for defining a restful resource

# 0.10.2 / 2015-11-15

  * Fixes issues presenting error views from gem
  * Fixes a bug causing routes to inherit hooks from previously defined routes
  * No longer resets the working context when redirecting or sending a file
  * Uses Rack's delete_cookie method rather than unset_cookie

# 0.10.0 / 2015-10-19

  * Adds nested route groups / namespaces inherit hooks
  * Static files are now served by default
  * Consistently handles externally defined config options
  * Adds post-processing step to route template expansions
  * Prevents the logger from breaking when no log to write to
  * Prevents resouces config from being reset on access
  * Don't add query params when route building
  * Fixes bug when defining nested restful routes
  * Support passing group + route name to `redir` and `reroute`
  * Updated status code names
  * Sets mime type of response when setting type
  * Exposes content type on response object
  * Adds support for `pakyow.data` in Rack env
  * Runs global config *after* local config
  * Makes JSON body available in request params
  * Fixes a bug in app reloading
  * Ported all tests to rspec
  * Adds the ability to halt execution in a 500 handler
  * Fixes namespace collisions
  * Use app's template for displaying Pakyow error views
  * Provides default values for helpers when no context available
  * Use `Bundler.require` to load dependencies in global config block
  * Respects before hook order
  * No longer overrides user-provided type when sending data/files

# 0.9.1 / 2014-12-06

  * No changes -- bumped version to be consistent

# 0.9.0 / 2014-11-09

  * Renames restful "remove" action to "delete"
  * Improves app generator bundle install by showing progress
  * Complete refactor of config handling with a shiny DSL
  * Includes pakyow-rake as a dependency, and updates the generated Rakefile
  * Removes support for Ruby versions < 2.0.0

# 0.8.0 / 2014-03-02

  * Major rewrite, including changes to app definition and routing

# 0.7.2 / 2012-02-29

  * Application server shuts down gracefully
  * Fix issue requesting route with format
  * Fix issue surrounding ignore_routes -- now matches request path in all cases

# 0.7.1 / 2012-01-08

  * Changed loader to only load ruby files
  * Moved session from app to request
  * Replaced autoload with require
  * Fixed generated rackup to use builder
  * Fixed generated rakefile so it runs in a specific environment
  * Fixed issue running with ignore_routes turned on

# 0.7.0 / 2011-11-19

  * Added middleware for logging, static, and reloading
  * Added invoke_route! and invoke_handler! methods
  * Added before, after, and around hooks to routes
  * Added pakyow console
  * Changed methods that modify request/response life cycle to bang methods
  * Fixed regex route error (was removing route vars)
  * App file is no longer loaded twice upon initialization
  * Fix cookie creation when cookie is a non-nil value but not a String

# 0.6.3 / 2011-09-13

  * Fixes several load path issues
  * Fixes gemspecs so gem can be built/used from anywhere
  * Fixes inconsistency with with request.params having string and symbol keys
  * Fixes loading of middleware when staging application (simplifies rackup)

# 0.6.2 / 2011-08-20

  * Fixes issue running pakyow server on Windows
  * Fixes several issues related to error handlers
  * Fixes an issue when using alphanumeric ids in restful routes
  * JRuby Support

# 0.6.1 / 2011-08-20

  * Fixes gemspec problem

# 0.6.0 / 2011-08-20

 * Initial gem release of 0.6.0 codebase
