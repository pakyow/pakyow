# v1.1.0 (unreleased)

  * `add` **Introduce log streaming from client to server for components in debug mode.**
    - Anything logged via `console` will also be logged on the server.
    - Set `debug: true` in the component config.

    *Related links:*
    - [Pull Request #304][pr-304]
    - [Commit dfe936b][dfe936b]
    - [Commit e855405][e855405]

  * `add` **Introduce a new `devtools` component.**
    - Automatically reloads the page when the code changes.
    - Click on mode to restart in development or prototype mode.
    - Gracefully handles the difference between uris in prototype and development modes.

    *Related links:*
    - [Pull Request #297][pr-297]
    - [Commit 802295c][802295c]

[pr-304]: https://github.com/pakyow/pakyow/pull/304/commits
[pr-297]: https://github.com/pakyow/pakyow/pull/297/commits
[e855405]: https://github.com/pakyow/pakyow/commit/e85540544296b06bf71e62db242d0c255e7552a9
[dfe936b]: https://github.com/pakyow/pakyow/commit/dfe936b63534ea19bb025f2f34c740dc95de8706
[802295c]: https://github.com/pakyow/pakyow/commit/802295c0396383b96fadafd121192d41bb63457e

# v1.0.0

  * Hello, Web
