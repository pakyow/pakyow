# v1.0.3 (unreleased)

  * `fix` **Start multiple processes when the process count specifies more than one.**

    *Related links:*
    - [Pull Request #329][pr-329]

  * `fix` **Prevent failed processes from restarting indefinitely.**

    *Related links:*
    - [Pull Request #328][pr-328]

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
