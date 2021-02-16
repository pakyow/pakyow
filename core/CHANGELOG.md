# v1.1.0 (unreleased)

  * `fix` **Load files with the expected module nesting.**

    *Related links:*
    - [Pull Request #554][pr-554]

  * `chg` **Support Ruby 3, Drop 2.6.**

    *Related links:*
    - [Pull Request #553][pr-553]

  * `fix` **Improve the reliability of container/service notifiers.**

    *Related links:*
    - [Pull Request #552][pr-552]

  * `chg` **Remove v1.0 deprecations.**

    *Related links:*
    - [Pull Request #551][pr-551]

  * `chg` **Run containers in their own process groups.**

    *Related links:*
    - [Pull Request #550][pr-550]

  * `chg` **Gracefully stop services that have blocked the reactor.**

    *Related links:*
    - [Pull Request #549][pr-549]

  * `chg` **Stop services with the notifier pattern.**

    *Related links:*
    - [Pull Request #548][pr-548]

  * `chg` **Drop Ruby 2.5 support.**

    *Related links:*
    - [Pull Request #547][pr-547]

  * `chg` **Gracefully shutdown containers and their services.**

    *Related links:*
    - [Pull Request #546][pr-546]

  * `chg` **Restructure containers to support running other services alongside servers.**

    *Related links:*
    - [Pull Request #543][pr-543]

  * `add` **Introduce an async container strategy.**

    *Related links:*
    - [Pull Request #542][pr-542]

  * `chg` **Make containers compatible with fiber-based reactors.**

    *Related links:*
    - [Pull Request #542][pr-542]

  * `fix` **Resolve a concurrency-related performance regression.**

    *Related links:*
    - [Pull Request #541][pr-541]

  * `chg` **Separate Pakyow's logging concerns from that of async.**

    *Related links:*
    - [Pull Request #540][pr-540]

  * `fix` **Maintain memory database connections when forking.**

    *Related links:*
    - [Pull Request #536][pr-536]

  * `fix` **Correctly validate values that might be false.**

    *Related links:*
    - [Pull Request #535][pr-535]

  * `fix` **Add fork events to the environment, called by containers.**

    *Related links:*
    - [Pull Request #533][pr-533]

  * `fix` **Resolve an issue causing params to be parsed twice.**

    *Related links:*
    - [Pull Request #530][pr-530]

  * `fix` **Reset params after setting an input parser on the connection.**

    *Related links:*
    - [Pull Request #529][pr-529]

  * `add` **Introduce the limiter action for limiting request body size.**

    *Related links:*
    - [Pull Request #528][pr-528]

  * `fix` **Don't register multiple deprecators with the global deprecator.**

    *Related links:*
    - [Pull Request #523][pr-523]

  * `chg` **Support `./common/lib` for multiapp projects.**

    *Related links:*
    - [Pull Request #518][pr-518]

  * `chg` **Define input parsers inline instead of on configure.**

    *Related links:*
    - [Pull Request #517][pr-517]

  * `fix` **Evalulate environment initializers in context of the environment.**

    *Related links:*
    - [Pull Request #516][pr-516]

  * `add` **Load backend aspects from the common folder.**

    *Related links:*
    - [Pull Request #515][pr-515]

  * `fix` **Load the environment before determining the server service count.**

    *Related links:*
    - [Pull Request #513][pr-513]

  * `chg` **Introduce `Pakyow.config.impolite` for controlling intro/goodbye logging.**

    *Related links:*
    - [Pull Request #512][pr-512]

  * `chg` **Disable the filewatcher in production and ludicrous modes.**

    *Related links:*
    - [Pull Request #511][pr-511]

  * `fix` **Load empty files without failing.**

    *Related links:*
    - [Pull Request #510][pr-510]

  * `chg` **Rename `Pakyow::Generator::File` to `Pakyow::Generator::Source` to prevent common namespace collisions.**

    *Related links:*
    - [Pull Request #509][pr-509]

  * `chg` **Load environment and application state in the lexical scope of the defined object.**

    *Related links:*
    - [Pull Request #509][pr-509]

  * `add` **Introduce `Pakyow::Logger.null` for creating null loggers.**

    *Related links:*
    - [Pull Request #508][pr-508]

  * `chg` **Ignore changes to directories in the filewatcher.**

    *Related links:*
    - [Pull Request #507][pr-507]

  * `chg` **Improve support for ignoring directories in filewatcher, add support for ignoring regular expressions.**

    *Related links:*
    - [Pull Request #506][pr-506]

  * `chg` **Improve automatic bundle install to catch failures, better logging.**

    *Related links:*
    - [Pull Request #505][pr-505]

  * `add` **Introduce `Pakyow::CLI.system` for running system commands.**

    *Related links:*
    - [Pull Request #505][pr-505]

  * `chg` **Pass diffs instead of full snapshots to filewatcher callbacks.**

    *Related links:*
    - [Pull Request #504][pr-504]

  * `add` **Introduce `Connection#subdomains` for getting subdomains as an array.**

    *Related links:*
    - [Pull Request #503][pr-503]

  * `fix` **Return multi-level subdomains from the connection.**

    *Related links:*
    - [Pull Request #503][pr-503]

  * `fix` **Create applications correctly in existing multiapp projects.**

    *Related links:*
    - [Pull Request #502][pr-502]

  * `fix` **Support setting the logger level as a string.**

    *Related links:*
    - [Pull Request #501][pr-501]

  * `chg` **Log at the debug level by default.**

    *Related links:*
    - [Pull Request #501][pr-501]

  * `fix` **Allow unmounted applications to be looked up but not receive requests.**

    *Related links:*
    - [Pull Request #500][pr-500]

  * `fix` **Correctly duplicate validator/verifier state.**

    *Related links:*
    - [Pull Request #499][pr-499]

  * `add` **Configure the environment and applications through environment variables.**

    *Related links:*
    - [Pull Request #497][pr-497]

  * `chg` **Don't use a service logger for the server service.**

    *Related links:*
    - [Pull Request #496][pr-496]

  * `chg` **Let services define their own loggers.**

    *Related links:*
    - [Pull Request #496][pr-496]

  * `fix` **Ensure that `Loader` always loads files alphabetically.**

    *Related links:*
    - [Pull Request #495][pr-495]

  * `fix` **Fix asset fetching for generated projects.**

    *Related links:*
    - [Pull Request #494][pr-494]

  * `add` **Expose results from operations.**

  * `fix` **Stop container notifiers more cleanly.**

    *Related links:*
    - [Pull Request #492][pr-492]

  * `add` **Generate new applications, converting existing projects to multiapp environments.**

    *Related links:*
    - [Pull Request #490][pr-490]

  * `chg` **Generate projects and applications with separate generators.**

    *Related links:*
    - [Pull Request #484][pr-484]

  * `fix` **Prevent deep freeze error when running formations.**

    *Related links:*
    - [Pull Request #488][pr-488]

  * `chg` **Don't sync logger destinations in production.**

    *Related links:*
    - [Pull Request #487][pr-487]

  * `chg` **Output logfmt events in a single write.**

    *Related links:*
    - [Pull Request #486][pr-486]

  * `chg` **Pass arguments through operations.**

    *Related links:*
    - [Pull Request #483][pr-483]

  * `chg` **Allow generators to define their own source paths.**

    *Related links:*
    - [Pull Request #481][pr-481]

  * `fix` **Resolve several issues with shared context in generators.**

    *Related links:*
    - [Pull Request #481][pr-481]

  * `chg` **Turn generators into operations.**

    *Related links:*
    - [Pull Request #481][pr-481]

  * `chg` **Define generators as state on the environment.**

    *Related links:*
    - [Pull Request #481][pr-481]

  * `chg` **Load commands after load instead of after configure.**

    *Related links:*
    - [Pull Request #480][pr-480]

  * `add` **Introduce release channels for safely defining pre-production behavior.**

    *Related links:*
    - [Pull Request #478][pr-478]

  * `chg` **Configure the environment within its load phase.**

    *Related links:*
    - [Pull Request #477][pr-477]

  * `add` **Specify mounted applications through the boot command.**

    *Related links:*
    - [Pull Request #476][pr-476]

  * `chg` **Run async reactors with the default or given logger.**

    *Related links:*
    - [Pull Request #475][pr-475]

  * `chg` **Run all parent services when running a nested formation.**

    *Related links:*
    - [Pull Request #474][pr-474]

  * `chg` **Initialize containers with options instead of passing through `run`.**

    *Related links:*
    - [Pull Request #473][pr-473]

  * `add` **Support a global `--config` CLI option.**

    *Related links:*
    - [Pull Request #472][pr-472]

  * `add` **Support a global `--debug` CLI flag.**

    *Related links:*
    - [Pull Request #471][pr-471]

  * `chg` **Hide CLI arguments, flags, and options without descriptions.**

    *Related links:*
    - [Pull Request #470][pr-470]

  * `fix` **Handle boot errors in services so that the environment or application is correctly rescued.**

    *Related links:*
    - [Pull Request #469][pr-469]

  * `add` **Introduce `Pakyow::Filewatcher` for reacting to changes in the filesystem.**

    *Related links:*
    - [Pull Request #468][pr-468]

  * `fix` **Fix service limits when count equals limit.**

    *Related links:*
    - [Pull Request #467][pr-467]

  * `chg` **Run Pakyow with a strategy.**

    *Related links:*
    - [Pull Request #466][pr-466]

  * `chg` **Yield after invoking a service in a container strategy.**

    *Related links:*
    - [Pull Request #465][pr-465]

  * `fix` **Don't rescue signal exceptions.**

    *Related links:*
    - [Pull Request #464][pr-464]

  * `fix` **Yield before running the container strategy.**

    *Related links:*
    - [Pull Request #463][pr-463]

  * `fix` **Correctly restart services when the container restarts.**

    *Related links:*
    - [Pull Request #462][pr-462]

  * `fix` **Handle magic comments in the loader.**

    *Related links:*
    - [Pull Request #461][pr-461]

  * `chg` **Support container restarts from child processes.**

    *Related links:*
    - [Pull Request #460][pr-460]

  * `chg` **Introduce the new hybrid container strategy, use by default.**

    *Related links:*
    - [Pull Request #459][pr-459]

  * `fix` **Run processes in a fiber to prevent immediate exits in nested processes.**

    *Related links:*
    - [Pull Request #458][pr-458]

  * `chg` **Introduce the new process model built on containers and services.**

    *Related links:*
    - [Pull Request #457][pr-457]

  * `fix` **Load outside of setup phase, setup outside of boot phase.**

    *Related links:*
    - [Pull Request #454][pr-454]

  * `fix` **Pass the environment to commands by default, explicitly setting up or booting as needed.**

    *Related links:*
    - [Pull Request #453][pr-453]

  * `chg` **Avoid loading the environment when running known commands that manage the boot phase.**

    *Related links:*
    - [Pull Request #451][pr-451]

  * `chg` **Prevent loading the same path twice by default, support explicit reloads.**

    *Related links:*
    - [Pull Request #450][pr-450]

  * `chg` **Refactor Pakyow::async to run a reactor.**

    *Related links:*
    - [Pull Request #449][pr-449]

  * `fix` **Update connection headers to be compatible with async-http@0.51.**

    *Related links:*
    - [Pull Request #445][pr-445]

  * `chg` **Improve cookie / session performance along with test coverage.**

    *Related links:*
    - [Pull Request #447][pr-447]

  * `add` **Add the rescue pattern to the environment.**

    *Related links:*
    - [Pull Request #444][pr-444]

  * `fix` **Make `Rack::Compatibility` compatible with protocol-http@0.16.**

    *Related links:*
    - [Pull Request #443][pr-443]

  * `chg` **Handle application errors through the normal error handling process.**

    *Related links:*
    - [Pull Request #442][pr-442]

  * `add` **Add event/error handling to applications, connections, and the environment.**

    *Related links:*
    - [Pull Request #440][pr-440]

  * `fix` **Log the epilogue even if another action halts.**

    *Related links:*
    - [Pull Request #436][pr-436]

  * `chg` **Call only the first application that accepts a request.**

    *Related links:*
    - [Pull Request #434][pr-434]

  * `add` **Let applications define connection acceptance with an `#accept?` method.**

    *Related links:*
    - [Pull Request #433][pr-433]

  * `add` **Introduce a `dispatch` event to the environment.**

    *Related links:*
    - [Pull Request #432][pr-432]

  * `chg` **Ensure that environment dispatch happens after user-defined actions.**

    *Related links:*
    - [Pull Request #431][pr-431]

  * `add` **Global error reporting through `Pakyow::houston`.**

    *Related links:*
    - [Pull Request #418][pr-418]

  * `add` **Split prelaunch commands into `prelaunch:build` and `prelaunch:release` phases.**
    - Build phase commands don't require a full boot and emit artifacts that alter the environment,
      such as by precompiling assets to the filesystem or uploading them to a CDN. The build phase
      runs when the project is built.
    - Release phase commands require a full boot and have the ability to directly alter the
      environment, such as by running database migrations. The release phase runs within the
      deployed project just before it boots.

    *Related links:*
    - [Pull Request #416][pr-416]

  * `chg` **Handle defining the same app multiple times.**

    *Related links:*
    - [Pull Request #413][pr-413]

  * `chg` **Improve error handling when running the environment.**

    *Related links:*
    - [Pull Request #412][pr-412]

  * `chg` **Assume all mounted applications are instances of `Pakyow::Application`.**

    *Related links:*
    - [Pull Request #411][pr-411]

  * `chg` **Accept the environment name in `Pakyow::boot` and `Pakyow::run`.**

    *Related links:*
    - [Pull Request #410][pr-410]

  * `chg` **Setup the environment as part of the boot phase, and setup applications in `setup` instead of `boot`.**

    *Related links:*
    - [Pull Request #410][pr-410]

  * `fix` **Setup the default environment deprecator to be forwarded to from global.**

    *Related links:*
    - [Pull Request #409][pr-409]

  * `chg` **Make each phase of the startup sequence idempotent.**
    - Includes `Pakyow::load`, `Pakyow::setup`, `Pakyow::boot`, `Pakyow::run`, and `Pakyow::Application::setup`.

    *Related links:*
    - [Pull Request #406][pr-406]

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

  * `./backend/lib` is deprecated in favor of `./lib`.

    *Related links:*
    - [Pull Request #519][pr-519]

  * `Pakyow::ProcessManager` is deprecated in favor of `Pakyow::Runnable::Container`.

    *Related links:*
    - [Pull Request #457][pr-457]

  * `Pakyow::Process` is deprecated in favor of `Pakyow::Runnable::Service`.

    *Related links:*
    - [Pull Request #457][pr-457]

  * `Pakyow.config.server` is deprecated in favor of `Pakyow.config.runnable.server`.

    *Related links:*
    - [Pull Request #457][pr-457]

  * `Pakyow.config.exit_on_boot_failure` is deprecated with no replacement.

    *Related links:*
    - [Pull Request #444][pr-444]

  * `Pakyow::Actions::Dispatch` is deprecated with no replacement.

    *Related links:*
    - [Pull Request #431][pr-431]

  * `Pakyow::load_apps` is deprecated with no replacement.

    *Related links:*
    - [Pull Request #410][pr-410]

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

[pr-554]: https://github.com/pakyow/pakyow/pull/554
[pr-553]: https://github.com/pakyow/pakyow/pull/553
[pr-551]: https://github.com/pakyow/pakyow/pull/551
[pr-550]: https://github.com/pakyow/pakyow/pull/550
[pr-549]: https://github.com/pakyow/pakyow/pull/549
[pr-548]: https://github.com/pakyow/pakyow/pull/548
[pr-547]: https://github.com/pakyow/pakyow/pull/547
[pr-546]: https://github.com/pakyow/pakyow/pull/546
[pr-543]: https://github.com/pakyow/pakyow/pull/543
[pr-542]: https://github.com/pakyow/pakyow/pull/542
[pr-541]: https://github.com/pakyow/pakyow/pull/541
[pr-540]: https://github.com/pakyow/pakyow/pull/540
[pr-536]: https://github.com/pakyow/pakyow/pull/536
[pr-535]: https://github.com/pakyow/pakyow/pull/535
[pr-533]: https://github.com/pakyow/pakyow/pull/533
[pr-530]: https://github.com/pakyow/pakyow/pull/530
[pr-529]: https://github.com/pakyow/pakyow/pull/529
[pr-528]: https://github.com/pakyow/pakyow/pull/528
[pr-523]: https://github.com/pakyow/pakyow/pull/523
[pr-518]: https://github.com/pakyow/pakyow/pull/518
[pr-517]: https://github.com/pakyow/pakyow/pull/517
[pr-516]: https://github.com/pakyow/pakyow/pull/516
[pr-515]: https://github.com/pakyow/pakyow/pull/515
[pr-513]: https://github.com/pakyow/pakyow/pull/513
[pr-512]: https://github.com/pakyow/pakyow/pull/512
[pr-511]: https://github.com/pakyow/pakyow/pull/511
[pr-510]: https://github.com/pakyow/pakyow/pull/510
[pr-509]: https://github.com/pakyow/pakyow/pull/509
[pr-508]: https://github.com/pakyow/pakyow/pull/508
[pr-507]: https://github.com/pakyow/pakyow/pull/507
[pr-506]: https://github.com/pakyow/pakyow/pull/506
[pr-505]: https://github.com/pakyow/pakyow/pull/505
[pr-504]: https://github.com/pakyow/pakyow/pull/504
[pr-503]: https://github.com/pakyow/pakyow/pull/503
[pr-502]: https://github.com/pakyow/pakyow/pull/502
[pr-501]: https://github.com/pakyow/pakyow/pull/501
[pr-500]: https://github.com/pakyow/pakyow/pull/500
[pr-499]: https://github.com/pakyow/pakyow/pull/499
[pr-497]: https://github.com/pakyow/pakyow/pull/497
[pr-496]: https://github.com/pakyow/pakyow/pull/496
[pr-495]: https://github.com/pakyow/pakyow/pull/495
[pr-494]: https://github.com/pakyow/pakyow/pull/494
[pr-492]: https://github.com/pakyow/pakyow/pull/492
[pr-490]: https://github.com/pakyow/pakyow/pull/490
[pr-484]: https://github.com/pakyow/pakyow/pull/484
[pr-488]: https://github.com/pakyow/pakyow/pull/488
[pr-487]: https://github.com/pakyow/pakyow/pull/487
[pr-486]: https://github.com/pakyow/pakyow/pull/486
[pr-483]: https://github.com/pakyow/pakyow/pull/483
[pr-481]: https://github.com/pakyow/pakyow/pull/481
[pr-480]: https://github.com/pakyow/pakyow/pull/480
[pr-478]: https://github.com/pakyow/pakyow/pull/478
[pr-477]: https://github.com/pakyow/pakyow/pull/477
[pr-476]: https://github.com/pakyow/pakyow/pull/476
[pr-475]: https://github.com/pakyow/pakyow/pull/475
[pr-474]: https://github.com/pakyow/pakyow/pull/474
[pr-473]: https://github.com/pakyow/pakyow/pull/473
[pr-472]: https://github.com/pakyow/pakyow/pull/472
[pr-471]: https://github.com/pakyow/pakyow/pull/471
[pr-470]: https://github.com/pakyow/pakyow/pull/470
[pr-469]: https://github.com/pakyow/pakyow/pull/469
[pr-468]: https://github.com/pakyow/pakyow/pull/468
[pr-467]: https://github.com/pakyow/pakyow/pull/467
[pr-466]: https://github.com/pakyow/pakyow/pull/466
[pr-465]: https://github.com/pakyow/pakyow/pull/465
[pr-464]: https://github.com/pakyow/pakyow/pull/464
[pr-463]: https://github.com/pakyow/pakyow/pull/463
[pr-462]: https://github.com/pakyow/pakyow/pull/462
[pr-461]: https://github.com/pakyow/pakyow/pull/461
[pr-460]: https://github.com/pakyow/pakyow/pull/460
[pr-459]: https://github.com/pakyow/pakyow/pull/459
[pr-458]: https://github.com/pakyow/pakyow/pull/458
[pr-457]: https://github.com/pakyow/pakyow/pull/457
[pr-454]: https://github.com/pakyow/pakyow/pull/454
[pr-453]: https://github.com/pakyow/pakyow/pull/453
[pr-451]: https://github.com/pakyow/pakyow/pull/451
[pr-450]: https://github.com/pakyow/pakyow/pull/450
[pr-449]: https://github.com/pakyow/pakyow/pull/449
[pr-447]: https://github.com/pakyow/pakyow/pull/447
[pr-445]: https://github.com/pakyow/pakyow/pull/445
[pr-443]: https://github.com/pakyow/pakyow/pull/443
[pr-442]: https://github.com/pakyow/pakyow/pull/442
[pr-440]: https://github.com/pakyow/pakyow/pull/440
[pr-436]: https://github.com/pakyow/pakyow/pull/436
[pr-434]: https://github.com/pakyow/pakyow/pull/434
[pr-433]: https://github.com/pakyow/pakyow/pull/433
[pr-432]: https://github.com/pakyow/pakyow/pull/432
[pr-431]: https://github.com/pakyow/pakyow/pull/431
[pr-418]: https://github.com/pakyow/pakyow/pull/418
[pr-416]: https://github.com/pakyow/pakyow/pull/416
[pr-413]: https://github.com/pakyow/pakyow/pull/413
[pr-412]: https://github.com/pakyow/pakyow/pull/412
[pr-411]: https://github.com/pakyow/pakyow/pull/411
[pr-410]: https://github.com/pakyow/pakyow/pull/410
[pr-409]: https://github.com/pakyow/pakyow/pull/409
[pr-406]: https://github.com/pakyow/pakyow/pull/406
[pr-405]: https://github.com/pakyow/pakyow/pull/405
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

# v1.0.4

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
