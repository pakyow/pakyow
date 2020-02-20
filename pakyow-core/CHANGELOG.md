# v1.1.0 (unreleased)

  * `chg` **Make the environment setup phase consistent with the app setup phase.**
    - Configure first, then load. Load the environment / application config files prior to configure and load.

    *Related links:*
    - [Pull Request #405][pr-405]

  * `chg` **Configure the environment as part of the load phase.**

    *Related links:*
    - [Pull Request #404][pr-404]

  * `fix` **Resolve several bugs related to the response body, `content-length` header, and `HEAD` requests.**

    *Related links:*
    - [Pull Request #402][pr-402]
    - [Commit 45c89dd][45c89dd]

  * `fix` **Failing commands now exit with an error status.**

    *Related links:*
    - [Pull Request #401][pr-401]

  * `add` **Introduce `Pakyow::Command`, definable on the environment.**
    - Will replace `Pakyow::Task` moving forward, as it's much simpler conceptually.

  * `chg` **Ensure that every potential operation value has an instance variable.**

    *Related links:*
    - [Pull Request #399][pr-399]

  * `chg` **Avoid using the setter for default values in operations.**

    *Related links:*
    - [Pull Request #398][pr-398]

  * `add` **Resolve default values that are blocks, introspect default values.**

    *Related links:*
    - [Pull Request #397][pr-397]

  * `fix` **Eval blocks passed to `verify` after the verifier is already defined.**

    *Related links:*
    - [Pull Request #395][pr-395]

  * `add` **Support verified value deprecations for operations.**

    *Related links:*
    - [Pull Request #394][pr-394]

  * `add` **Define public readers and private writers for verified operation values.**
    - This is a bit of an optimization and will allow aspects of an operation's api to be deprecated.

    *Related links:*
    - [Pull Request #392][pr-392]

  * `add` **Introduce class-level verifiers, with the ability to call them from the verifiable instance.**

    *Related links:*
    - [Pull Request #391][pr-391]

  * `add` **Specify default values from optional verified values.**

    *Related links:*
    - [Pull Request #390][pr-390]

  * `chg` **Operation state can be accessed/changed via getters/setters or instance variables.**

    *Related links:*
    - [Pull Request #388][pr-388]
    - [Commit 3268e57][3268e57]

  * `fix` **Avoid deep duping during verification.**

    *Related links:*
    - [Pull Request #386][pr-386]

  * `chg` **Setup applications on the class rather than the instance.**

    *Related links:*
    - [Pull Request #380][pr-380]
    - [Commit 92f795e][92f795e]

  * `chg` **Build endpoints explicitly, relative to app mount path.**

    *Related links:*
    - [Pull Request #374][pr-374]
    - [Commit d7ef764][d7ef764]

  * `chg` **Boot the environment once, prior to forking child processes.**

    *Related links:*
    - [Pull Request #348][pr-348]
    - [Commit 641fd12][641fd12]

  * `chg` **Run the environment in context of an async reactor.**

    *Related links:*
    - [Pull Request #347][pr-347]
    - [Commit 991f3dd][991f3dd]

  * `chg` **Initialize thread local logger with key, support setting the thread local logger.**

    *Related links:*
    - [Pull Request #344][pr-344]
    - [Commit ac9c7a9][ac9c7a9]

  * `chg` **Support silencing in the thread local logger.**

    *Related links:*
    - [Pull Request #344][pr-344]
    - [Commit 04e82ff][04e82ff]

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

  * `Pakyow::Processes::Proxy::find_local_port` is deprecated, replaced with `Pakyow::Support::System::available_port`.

    *Related links:*
    - [Pull Request #402][pr-402]
    - [Commit be0e450][be0e450]

  * The environment's `server.proxy` config option is deprecated with no replacement.

    *Related links:*
    - [Pull Request #402][pr-402]
    - [Commit 7c9850c][7c9850c]

  * `Pakyow::Processes::Proxy` and `Pakyow::Processes::Proxy::Server` are deprecated with no replacement.

    *Related links:*
    - [Pull Request #402][pr-402]
    - [Commit 7c9850c][7c9850c]

  * `Pakyow::Task` is deprecated in favor of `Pakyow::Command`.

    *Related links:*
    - [Pull Request #401][pr-401]

  * `Pakyow::Operation#values` is deprecated in favor of value methods.

    *Related links:*
    - [Pull Request #388][pr-388]
    - [Commit 7f0df61][7f0df61]

  * `Pakyow::Endpoints#load` is deprecated in favor of registering endpoints explicitly with `Pakyow::Endpoints#build`.

    *Related links:*
    - [Pull Request #374][pr-374]
    - [Commit 649cb97][649cb97]

  * The environment's `freeze_on_boot` config option is deprecated and will be removed.

    *Related links:*
    - [Pull Request #348][pr-348]
    - [Commit c75ca74][c75ca74]

  * `Pakyow::Logger#silence` is deprecated in favor of `Pakyow::Logger::ThreadLocal#silence`.

    *Related links:*
    - [Pull Request #344][pr-344]
    - [Commit c75ca74][c75ca74]

  * `Pakyow::ProcessManager#add` no longer accepts a `Hash`.

    *Related links:*
    - [Pull Request #339][pr-339]
    - [Commit be9b292][be9b292]

  * `Pakyow::global_logger` has been deprecated in favor of `Pakyow::output`.

    *Related links:*
    - [Pull Request #338][pr-338]

[pr-505]: https://github.com/pakyow/pakyow/pull/505
[pr-404]: https://github.com/pakyow/pakyow/pull/404
[pr-402]: https://github.com/pakyow/pakyow/pull/402
[pr-401]: https://github.com/pakyow/pakyow/pull/401
[pr-399]: https://github.com/pakyow/pakyow/pull/399
[pr-398]: https://github.com/pakyow/pakyow/pull/398
[pr-397]: https://github.com/pakyow/pakyow/pull/397
[pr-395]: https://github.com/pakyow/pakyow/pull/395
[pr-394]: https://github.com/pakyow/pakyow/pull/394
[pr-392]: https://github.com/pakyow/pakyow/pull/392
[pr-391]: https://github.com/pakyow/pakyow/pull/391
[pr-390]: https://github.com/pakyow/pakyow/pull/390
[pr-388]: https://github.com/pakyow/pakyow/pull/388
[pr-386]: https://github.com/pakyow/pakyow/pull/386
[pr-380]: https://github.com/pakyow/pakyow/pull/380
[pr-374]: https://github.com/pakyow/pakyow/pull/374
[pr-348]: https://github.com/pakyow/pakyow/pull/348
[pr-347]: https://github.com/pakyow/pakyow/pull/347
[pr-344]: https://github.com/pakyow/pakyow/pull/344
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
[45c89dd]: https://github.com/pakyow/pakyow/commit/45c89ddb3f3ecdef61524eedfa08c3bc8e16696d
[be0e450]: https://github.com/pakyow/pakyow/commit/be0e45092f31f038c10dc287cc96a887e092d146
[7c9850c]: https://github.com/pakyow/pakyow/commit/7c9850ce123a5bf714ad91b485e180ee60a014c2
[7f0df61]: https://github.com/pakyow/pakyow/commit/7f0df61a917b948030b0c44243bdb434e76c999c
[3268e57]: https://github.com/pakyow/pakyow/commit/3268e57203e13c3c448f67585d29e3e2f67fe462
[92f795e]: https://github.com/pakyow/pakyow/commit/92f795e88e1ca3106394d0581d51f17cf1a883ad
[649cb97]: https://github.com/pakyow/pakyow/commit/649cb97cf747c3ab6bbe197ba63c554f4d05a76e
[d7ef764]: https://github.com/pakyow/pakyow/commit/d7ef76437f4c8948ac09d9b5be77bc02a44caa06
[641fd12]: https://github.com/pakyow/pakyow/commit/641fd12b5abee8558621caf857cec47d38814c8a
[12de611]: https://github.com/pakyow/pakyow/commit/12de611e480fb9224f1e0bdaf9bd902448dd69e3
[991f3dd]: https://github.com/pakyow/pakyow/commit/991f3ddd589edc9d08370c4f020e2ef0297433c7
[c75ca74]: https://github.com/pakyow/pakyow/commit/c75ca749595e8e6f6e5950fc19f528e7c02230d7
[ac9c7a9]: https://github.com/pakyow/pakyow/commit/ac9c7a95afef1b86ba5946d34269480e1d5f9081
[04e82ff]: https://github.com/pakyow/pakyow/commit/04e82fffb77b3c72b3fbb4783744c9d4bdec1a25
[be9b292]: https://github.com/pakyow/pakyow/commit/be9b292ba090976667b3c7a1ee6314cda7995591
[d55e932]: https://github.com/pakyow/pakyow/commit/d55e9320dcca51ac7d12d8eef4f7f8aaf8faaa4f
[26f586d]: https://github.com/pakyow/pakyow/commit/26f586d35c5fa0611cac6914fb2f249e3798ec79

# v1.0.4 (unreleased)

  * `fix` **Typecast header values to strings.**
    - Resolves an incompatibility with `protocol-http`.

    *Related links:*
    - [Pull Request #400][pr-400]

  * `fix` **Bundler deprecation warnings (prefer `with_original_env`).**

    *Related links:*
    - [Commit 7b8511a][7b8511a]

[pr-400]: https://github.com/pakyow/pakyow/pull/400
[7b8511a]: https://github.com/pakyow/pakyow/commit/7b8511a079ffdc2672aa95ee9a2966b21ec2c506

# v1.0.3

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
