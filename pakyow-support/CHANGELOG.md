# v1.1.0 (unreleased)

  * `chg` **Configure defaults for multiple environments at one time.**
    - `Config` now supports multiple default config blocks per environnment.
    - `Config#defaults` now supports passing multiple environments.

    *Related links:*
    - [Commit 787681d][787681d]

[787681d]: https://github.com/pakyow/pakyow/commit/787681dacbbd3ce79f6e38a5672749635903a85b

# v1.0.2

  * `fix` **Message verification no longer fails when the digest contains `--`.**

    *Related links:*
    - [Pull Request #316][pr-316]

  * `fix` **Avoid including the initializer for configurable modules.**

    *Related links:*
    - [Pull Request #312][pr-312]

  * `fix` **Methods defined an an app block are now defined in the correct context.**

    *Related links:*
    - [Commit 62112dc][62112dc]
    - [Commit f7591d4][f7591d4]

  * `fix` **Named actions can now share a name with a method on the pipelined object.**

    *Related links:*
    - [Pull Request #297][pr-297]
    - [Commit fe1f554][fe1f554]

[pr-316]: https://github.com/pakyow/pakyow/pull/316/commits
[pr-312]: https://github.com/pakyow/pakyow/pull/312/commits
[pr-297]: https://github.com/pakyow/pakyow/pull/297/commits
[f7591d4]: https://github.com/pakyow/pakyow/commit/f7591d406fd87c04eee3ee036da6a780188971b6
[62112dc]: https://github.com/pakyow/pakyow/commit/62112dc1396e397fda73e92df780c4358e28a3fa
[fe1f554]: https://github.com/pakyow/pakyow/commit/fe1f554b56a4c22298f8c2b7809519a9b8eb220b

# v1.0.0

  * Hello, Web
