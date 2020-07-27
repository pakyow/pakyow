# v1.1.0 (unreleased)

  * `chg` **Improve output when fetching external assets.**

  * `fix` **Don't relocate assets when the assets framework is not included.**

    *Related links:*
    - [Pull Request #502][pr-502]

  * `fix` **Avoid precompiling assets for applications that don't include the assets framework.**

    *Related links:*
    - [Pull Request #498][pr-498]

  * `chg` **Relocate external asset fetching to an environment service.**

    *Related links:*
    - [Pull Request #468][pr-468]

  * `chg` **Refactor Babel to be a `Pakyow::Assets::Script`.**

    *Related links:*
    - [Pull Request #439][pr-439]

  * `chg` **Replace uglifier with terser.**

    *Related links:*
    - [Pull Request #438][pr-438]

  * `chg` **Update @babel/standalone to 7.9.4.**

    *Related links:*
    - [Pull Request #437][pr-437]

  * `add` **Devtools component is now an autoloaded pack in `development` and `prototype` modes.**

    *Related links:*
    - [Pull Request #297][pr-297]
    - [Commit 802295c][802295c]

## Deprecations

  * `Pakyow::Assets::Types::CSS`, `Pakyow::Assets::Types::JS`, `Pakyow::Assets::Types::Sass`, and
    `Pakyow::Assets::Types::Scss` are all deprecated with no direct replacement.

    *Related links:*
    - [Pull Request #376][pr-376]
    - [Commit ec13cdd][ec13cdd]

[pr-502]: https://github.com/pakyow/pakyow/pull/502
[pr-498]: https://github.com/pakyow/pakyow/pull/498/commits
[pr-468]: https://github.com/pakyow/pakyow/pull/468/commits
[pr-438]: https://github.com/pakyow/pakyow/pull/438/commits
[pr-437]: https://github.com/pakyow/pakyow/pull/437/commits
[pr-376]: https://github.com/pakyow/pakyow/pull/376/commits
[pr-297]: https://github.com/pakyow/pakyow/pull/297/commits
[ec13cdd]: https://github.com/pakyow/pakyow/commit/ec13cdde0b7926d35e0a340fc93889d4166882dd
[802295c]: https://github.com/pakyow/pakyow/commit/802295c0396383b96fadafd121192d41bb63457e

# v1.0.5

  * `fix` **Download external asset content in full.**

    *Related links:*
    - [Pull Request #415][pr-415]

[pr-415]: https://github.com/pakyow/pakyow/pull/415/

# v1.0.4

  * `fix` **Escape external asset uris so they do not fail on fetch.**

    *Related links:*
    - [Commit e2d7e2e][e2d7e2e]

[e2d7e2e]: https://github.com/pakyow/pakyow/commit/e2d7e2ea2f36cb0a4c7073c17a692423b5cd1efe

# v1.0.3

  * `fix` **Make `pakyow/assets` compatible with Ruby 2.7.0.**
    - External assets used the `http` gem, which is failing on Ruby 2.7.0-preview3. We replaced it
    with the `async-http` gem which is already a dependency of other Pakyow frameworks.

    *Related links:*
    - [Pull Request #362][pr-362]
    - [Commit 4278340][4278340]

[pr-362]: https://github.com/pakyow/pakyow/pull/362/commits
[4278340]: https://github.com/pakyow/pakyow/commit/4278340178abea1dc7891ed02d098c5b747b2d5b

# v1.0.2

  * `fix` **CDN prefix is now correctly added to assets in plugin views.**

    *Related links:*
    - [Commit 84da911][84da911]

[84da911]: https://github.com/pakyow/pakyow/commit/84da911d78a33e0328bc64a7051f56268f088273

# v1.0.0

  * Hello, Web
