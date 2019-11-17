# v1.1.0 (unreleased)

  * `chg` **Improve `Pakyow::ProcessManager` api with the addition of a `Pakyow::Process` value object.**

    *Related links:*
    - [Pull Request #339][pr-339]
    - [Commit be9b292][be9b292]

  * `chg` **Rename `Pakyow::global_logger` to `Pakyow::output`.**

    *Related links:*
    - [Pull Request #338][pr-338]

  * `add` **Provide an environment-level deprecator.**

    *Related links:*
    - [Pull Request #335][pr-335]

  * `chg` **Improve bundle bootstrapping to be ~200ms faster.**

    *Related links:*
    - [Pull Request #321][pr-321]

  * `add` **Configure normalization through a canonical uri.**

    *Related links:*
    - [Pull Request #314][pr-314]

  * `add` **Require https by default when running in production.**

    *Related links:*
    - [Pull Request #313][pr-313]

  * `add` **Enforce https rules in the normalizer controlled through three new config options:**

    1. `normalizer.strict_https`: Enforces the https requirement if true.
    2. `normalizer.require_https`: Requires https scheme if true, otherwise http.
    3. `normalizer.allowed_http_hosts`: Array of hosts that are allowed as http (e.g. localhost).

    *Related links:*
    - [Pull Request #313][pr-313]

  * `add` **Better error messages when running commands in the wrong context.**

    *Related links:*
    - [Pull Request #303][pr-303]
    - [Issue #298][is-298]

  * `add` **Fetch external assets when creating a new project.**

    *Related links:*
    - [Pull Request #302][pr-302]

  * `add` **Generate projects from a template with the new `--template` option.**
    - Includes a new `example` template with styles for the 5-minute app example.

    *Related links:*
    - [Pull Request #301][pr-301]
    - [Commit d55e932][d55e932]

  * `add` **Trigger restarts through an http endpoint.**
    - Only available when running development and prototype environments.
    - Adds the ability to restart or respawn into a particular environment by writing it to `tmp/restart.txt`.
    - Adds explicit names to several environment actions for attaching new behavior before/after.
    - Now reuses the same port for respawns, just like we do restarts.

    *Related links:*
    - [Pull Request #297][pr-297]
    - [Commit 26f586d][26f586d]

## Deprecations

  * `Pakyow::ProcessManager#add` no longer accepts a `Hash`.

    *Related links:*
    - [Pull Request #339][pr-339]
    - [Commit be9b292][be9b292]

  * `Pakyow::global_logger` has been deprecated in favor of `Pakyow::output`.

    *Related links:*
    - [Pull Request #338][pr-338]

[pr-339]: https://github.com/pakyow/pakyow/pull/339
[pr-338]: https://github.com/pakyow/pakyow/pull/338
[pr-335]: https://github.com/pakyow/pakyow/pull/335
[pr-321]: https://github.com/pakyow/pakyow/pull/321
[pr-314]: https://github.com/pakyow/pakyow/pull/314
[pr-313]: https://github.com/pakyow/pakyow/pull/313
[pr-303]: https://github.com/pakyow/pakyow/pull/303
[pr-302]: https://github.com/pakyow/pakyow/pull/302
[pr-301]: https://github.com/pakyow/pakyow/pull/301
[is-298]: https://github.com/pakyow/pakyow/issues/298
[pr-297]: https://github.com/pakyow/pakyow/pull/297
[be9b292]: https://github.com/pakyow/pakyow/commit/be9b292ba090976667b3c7a1ee6314cda7995591
[d55e932]: https://github.com/pakyow/pakyow/commit/d55e9320dcca51ac7d12d8eef4f7f8aaf8faaa4f
[26f586d]: https://github.com/pakyow/pakyow/commit/26f586d35c5fa0611cac6914fb2f249e3798ec79

# v1.0.3 (unreleased)

  * `fix` **Resolve several issues with respawns, restarts.**

    *Related links:*
    - [Pull Request #342][pr-342]

  * `fix` **Ensure a logger and output is always available in the environment.**

    *Related links:*
    - [Pull Request #331][pr-331]

  * `fix` **Start multiple processes when the process count specifies more than one.**

    *Related links:*
    - [Pull Request #329][pr-329]

  * `fix` **Prevent failed processes from restarting indefinitely.**

    *Related links:*
    - [Pull Request #328][pr-328]

[pr-342]: https://github.com/pakyow/pakyow/pull/342
[pr-331]: https://github.com/pakyow/pakyow/pull/331
[pr-329]: https://github.com/pakyow/pakyow/pull/329
[pr-328]: https://github.com/pakyow/pakyow/pull/328

# v1.0.2

  * `fix` **Relocate `version.rb` from the meta gem into `pakyow/core`.**
    - Makes it possible to use `pakyow/core` and other gems without needing the meta gem.

    *Related links:*
    - [Pull Request #320][pr-320]

  * `fix` **Query string missing from normalized uris.**

    *Related links:*
    - [Pull Request #315][pr-315]

  * `fix` **Remove recursive require from `logger/colorizer.rb`.**

    *Related links:*
    - [Pull Request #311][pr-311]

  * `fix` **Always load `config/application` relative to `Pakyow.config.root`.**

    *Related links:*
    - [Pull Request #310][pr-310]

  * `fix` **Issue with `Pakyow::Error` not detecting gems in rvm.**

    *Related links:*
    - [Pull Request #306][pr-306]

  * `fix` **Correct several issues with incorrect error backtraces, improve performance.**

    *Related links:*
    - [Commit cdb9e15][cdb9e15]

  * `fix` **App connection path is relative to to the app mount path.**

    *Related links:*
    - [Commit fc6209f][fc6209f]

  * `fix` **Backend aspects now load alphabetically on every system.**

    *Related links:*
    - [Commit 47189b7][47189b7]

  * `fix` **Respawn into the correct environment by clearing `tmp/restart.txt`.**

    *Related links:*
    - [Commit c9d5544][c9d5544]

  * `fix` **CLI short code arguments are now passed to the task in the correct order.**

    *Related links:*
    - [Commit 8604c1e][8604c1e]

[pr-320]: https://github.com/pakyow/pakyow/pull/320
[pr-315]: https://github.com/pakyow/pakyow/pull/315
[pr-311]: https://github.com/pakyow/pakyow/pull/311
[pr-310]: https://github.com/pakyow/pakyow/pull/310
[pr-306]: https://github.com/pakyow/pakyow/pull/306
[cdb9e15]: https://github.com/pakyow/pakyow/commit/cdb9e15f9840da4b5e909dc29b68c70ffa996a36
[fc6209f]: https://github.com/pakyow/pakyow/commit/fc6209fa12f1a0865cbd1a9c7c7f74e853a83a2a
[47189b7]: https://github.com/pakyow/pakyow/commit/47189b7d9fbb443f593f8e1573ddd6532ece9008
[c9d5544]: https://github.com/pakyow/pakyow/commit/cdb9e15f9840da4b5e909dc29b68c70ffa996a36
[8604c1e]: https://github.com/pakyow/pakyow/commit/8604c1e43a559acba9ab123586eb85d71df92691

# v1.0.1

  * Rename `navigable` to `navigator` in the generated app.

    *Related links:*
    - [Commit bc7d9a3][bc7d9a3]

[bc7d9a3]: https://github.com/pakyow/pakyow/commit/bc7d9a39031a28e05c91a614d7e447ab061ede21

# v1.0.0

  * Hello, Web
