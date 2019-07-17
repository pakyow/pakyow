# UNRELEASED

  * [added] Environment action for triggering restarts at an http endpoint
    * Only available when running development and prototype environments
  * [added] Ability to restart or respawn into a particular environment by writing to the tmp file
  * [added] Explicit names to environment actions for attaching new behavior before/after
  * [changed] Reuse the same port for respawns, just like we do restarts
  * [added] Ability to generate a project from a template with the `--template` option
  * [added] New "example" template with styles for the 5-minute app example
  * [added] Fetch external assets when creating a new project
  * [added] Better error messages when running commands in the wrong context
  * [fixed] Unpredictable load order of backend aspects
    * Now loaded alphabetically on every os
  * [fixed] App connection path is relative to to the app mount path
  * [fixed] Methods defined an an app block are now correctly defined
  * [fixed] Issue with `Pakyow::Error` not detecting gems in rvm
  * [added] Enforce https rules in the normalizer controlled through two new config options:
    * `normalizer.strict_https`: Enforces the https requirement if true
    * `normalizer.require_https`: Requires https scheme if true, otherwise http
  * [added] Require https by default when running in production

# 1.0.1

  * Rename "navigable" to "navigator" in the generated app

# 1.0.0

  * Hello, Web
