# v1.1.0 (unreleased)

  * `add` **Devtools component is now an autoloaded pack in `development` and `prototype` modes.**

    *Related links:*
    - [Pull Request #297][pr-297]
    - [Commit 802295c][802295c]

[pr-297]: https://github.com/pakyow/pakyow/pull/297/commits
[802295c]: https://github.com/pakyow/pakyow/commit/802295c0396383b96fadafd121192d41bb63457e

# v1.0.3 (unreleased)

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
