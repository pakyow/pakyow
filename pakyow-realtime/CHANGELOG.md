# v1.1.0 (unreleased)

  * `chg` **Installed WebSocket is now configured to be a global socket.**

    *Related links:*
    - [Pull Request #304][pr-304]
    - [Commit c4b0271][c4b0271]

  * `add` **Introduce WebSocket message handlers.**

    *Related links:*
    - [Pull Request #304][pr-304]
    - [Commit 637566f][637566f]

  * `chg` **Improve WebSocket heartbeats.**
    - Let WebSocket instances manage their own heartbeats.
    - Send heartbeats every second from WebSocket instances.

    *Related links:*
    - [Pull Request #296][pr-296]

[pr-304]: https://github.com/pakyow/pakyow/pull/304
[pr-296]: https://github.com/pakyow/pakyow/pull/296
[c4b0271]: https://github.com/pakyow/pakyow/commit/c4b02716363a098a2367a255b04edf0dfe1fb6f5
[637566f]: https://github.com/pakyow/pakyow/commit/637566f207e6ddda1689412ef29303ffe2767f9f

# v1.0.2 (unreleased)

  * `fix` **Issue causing data subscriptions to never be expired for a web socket connection.**

    *Related links:*
    - [Pull Request #295][pr-295]

[pr-295]: https://github.com/pakyow/pakyow/pull/295

# v1.0.0

  * Hello, Web
