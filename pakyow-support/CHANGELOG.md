# v1.1.0 (unreleased)

  * `chg` **Allow configurable instances to be extended.**

    *Related links:*
    - [Pull Request #456][pr-456]

  * `fix` **Handle exceptions in handleable objects.**

    *Related links:*
    - [Pull Request #455][pr-455]

  * `fix` **Don't freeze the internal state of insulated objects.**

    *Related links:*
    - [Pull Request #452][pr-452]

  * `fix` **Build state on configurable instances prior to freezing.**

    *Related links:*
    - [Pull Request #441][pr-441]

  * `add` **Introduce `Handleable` for handling events (such as errors) on your objects.**

    *Related links:*
    - [Pull Request #417][pr-417]

  * `chg` **Improve pipeline call performance.**

    *Related links:*
    - [Pull Request #430][pr-430]

  * `chg` **Allow pipelines to be called without state.**

    *Related links:*
    - [Pull Request #429][pr-429]

  * `chg` **Improve the ability to define actions on a pipeline instance.**

    *Related links:*
    - [Pull Request #428][pr-428]

  * `add` **Introduce `Pipeline#rcall` for calling pipelines in reverse.**

    *Related links:*
    - [Pull Request #427][pr-427]

  * `chg` **Handle argument globs in method introspections.**

    *Related links:*
    - [Pull Request #426][pr-426]

  * `chg` **Pass keyword arguments through pipelines.**

    *Related links:*
    - [Pull Request #425][pr-425]

  * `add` **Introduce `#argument_list?` refinement for `Proc`, `Method`, and `UnboundMethod` introspection.**

    *Related links:*
    - [Pull Request #424][pr-424]

  * `add` **Introduce `UnboundMethod` introspection refinements.**

    *Related links:*
    - [Pull Request #423][pr-423]

  * `add` **Introduce `Method#keyword_arguments?` and `Proc#keyword_arguments?` refinements.**

    *Related links:*
    - [Pull Request #422][pr-422]

  * `chg` **Improve pipeline performance.**

    *Related links:*
    - [Pull Request #421][pr-421]

  * `add` **Support rejection in pipelines.**

    *Related links:*
    - [Pull Request #420][pr-420]

  * `add` **Introduce `Extension::common_prepend_methods` to prepend methods to an instance and class.**

    *Related links:*
    - [Pull Request #419][pr-419]

  * `fix` **Ensure that defined state maintains the original definition order.**

    *Related links:*
    - [Pull Request #414][pr-414]

  * `fix` **Prevent multiple forwards to the same deprecator.**

    *Related links:*
    - [Pull Request #408][pr-408]

  * `chg` **Don't present spinner when running commands outside a tty.**

    *Related links:*
    - [Pull Request #403][pr-403]

  * `fix` **Correctly define and find namespaced definable state.**

    *Related links:*
    - [Pull Request #396][pr-396]

  * `fix` **Allow private instance methods to be deprecated.**

    *Related links:*
    - [Pull Request #393][pr-393]

  * `fix` **Deprecated instance methods are no longer available on the class.**

    *Related links:*
    - [Pull Request #389][pr-389]

  * `add` **Introduce `Inspectable::uninspectable` for opting out of inspecting specific object state.**

    *Related links:*
    - [Pull Request #387][pr-387]
    - [Commit 8eefc4a][8eefc4a]

  * `chg` **`Inspectable` objects now inspect all instance state by default.**

    *Related links:*
    - [Pull Request #387][pr-387]
    - [Commit 244d4f6][244d4f6]

  * `chg` **Support ignores in the global deprecator.**

    *Related links:*
    - [Pull Request #385][pr-385]

  * `chg` **Build config classes for configurable objects.**

    *Related links:*
    - [Pull Request #383][pr-383]

  * `chg` **Support passing the isolable context through makeable.**

    *Related links:*
    - [Pull Request #384][pr-384]

  * `chg` **Remove the ability to define definable state on instances.**
    - This caused namespace collisions when defining state with the same name on two instances.

    *Related links:*
    - [Pull Request #380][pr-380]
    - [Commit 9ef221b][9ef221b]

  * `add` **Introduce config deprecations.**

    *Related links:*
    - [Pull Request #379][pr-379]

  * `chg` **Support deprecating dynamic instance methods defined on a singleton.**

    *Related links:*
    - [Pull Request #378][pr-378]

  * `fix` **Report deprecations correctly for previously anonymous classes.**

    *Related links:*
    - [Pull Request #377][pr-377]

  * `add` **Publicize `Definable`, `Makeable`.**
    - These two modules introduce patterns for defining isolated state on an object.
    - Resolves several related bugs across all frameworks, including:
      - Defining named state within an anonymous parent will result in the defined state also being
        anonymous rather than being defined in the top-level namespace.

    *Related links:*
    - [Pull Request #376][pr-376]
    - [Commit 59d983b][59d983b]

  * `chg` **Make default isolable context overridable.**

    *Related links:*
    - [Pull Request #373][pr-373]

  * `chg` **Set isolable object name even when isolated object is anonymous.**

    *Related links:*
    - [Pull Request #372][pr-372]

  * `chg` **Support complex object naming in isolable.**

    *Related links:*
    - [Pull Request #371][pr-371]

  * `fix` **Build the correct object name when namespace is empty.**

    *Related links:*
    - [Pull Request #370][pr-370]

  * `add` **Allow object name to be passed explicitly when isolating an object.**

    *Related links:*
    - [Pull Request #369][pr-369]

  * `chg` **Pass isolable namespace as a keyword argument.**

    *Related links:*
    - [Pull Request #368][pr-368]

  * `chg` **Rename isolable binding to context.**

    *Related links:*
    - [Pull Request #367][pr-367]

  * `chg` **Improve isolated module inheritance.**

    *Related links:*
    - [Pull Request #366][pr-366]

  * `chg` **Register pipeline actions during initialization.**

    *Related links:*
    - [Pull Request #365][pr-365]

  * `add` **Introduce `Pipeline::Extension`.**

    *Related links:*
    - [Pull Request #364][pr-364]

  * `add` **Introduce `Isolable`.**

    *Related links:*
    - [Pull Request #363][pr-363]

  * `add` **Add a `common_methods` pattern to extensions.**

    *Related links:*
    - [Pull Request #361][pr-361]

  * `add` **Expose `source_location`.**

    *Related links:*
    - [Pull Request #359][pr-359]

  * `add` **Expose `object_name` for makeable, definable objects.**

    *Related links:*
    - [Pull Request #358][pr-358]

  * `add` **Introduce `ObjectName`, `ObjectNamespace`.**

    *Related links:*
    - [Pull Request #357][pr-357]

  * `chg` **Extension restriction violations now raise `RuntimeError`.**

    *Related links:*
    - [Pull Request #352][pr-352]
    - [Commit d410904][d410904]

  * `add` **Add `Extension#include_dependency` and `Extension#extend_dependency`.**

    *Related links:*
    - [Pull Request #352][pr-352]
    - [Commit 3edf137][3edf137]

  * `add` **Introduce `Deprecatable`.**

    *Related links:*
    - [Pull Request #351][pr-351]

  * `add` **Add `Deprecator#ignore`.**
    - Allows deprecations to be ignored during the execution of a block.

    *Related links:*
    - [Pull Request #349][pr-349]

  * `add` **Insulate `Socket`/`IO` from deep freezing.**

    *Related links:*
    - [Pull Request #343][pr-343]
    - [Commit 59e6efe][59e6efe]

  * `add` **Let objects to insulate themselves from a deep freeze.**

    *Related links:*
    - [Pull Request #340][pr-340]

  * `add` **Introduce `Pakyow::Support::Deprecator`**

    *Related links:*
    - [Pull Request #330][pr-330]

  * `chg` **Configure defaults for multiple environments at one time.**
    - `Config` now supports multiple default config blocks per environnment.
    - `Config#defaults` now supports passing multiple environments.

    *Related links:*
    - [Commit 787681d][787681d]

## Deprecations

  * Pipeline extensions should be created with `extend Pakyow::Support::Pipeline::Extension` instead
    of using `extend Pakyow::Support::Pipeline`.

    *Related links:*
    - [Pull Request #364][pr-364]

[pr-456]: https://github.com/pakyow/pakyow/pull/456
[pr-455]: https://github.com/pakyow/pakyow/pull/455
[pr-452]: https://github.com/pakyow/pakyow/pull/452
[pr-441]: https://github.com/pakyow/pakyow/pull/441
[pr-430]: https://github.com/pakyow/pakyow/pull/430
[pr-429]: https://github.com/pakyow/pakyow/pull/429
[pr-428]: https://github.com/pakyow/pakyow/pull/428
[pr-427]: https://github.com/pakyow/pakyow/pull/427
[pr-426]: https://github.com/pakyow/pakyow/pull/426
[pr-425]: https://github.com/pakyow/pakyow/pull/425
[pr-424]: https://github.com/pakyow/pakyow/pull/424
[pr-423]: https://github.com/pakyow/pakyow/pull/423
[pr-422]: https://github.com/pakyow/pakyow/pull/422
[pr-421]: https://github.com/pakyow/pakyow/pull/421
[pr-420]: https://github.com/pakyow/pakyow/pull/420
[pr-419]: https://github.com/pakyow/pakyow/pull/419
[pr-417]: https://github.com/pakyow/pakyow/pull/417
[pr-414]: https://github.com/pakyow/pakyow/pull/414
[pr-408]: https://github.com/pakyow/pakyow/pull/408
[pr-403]: https://github.com/pakyow/pakyow/pull/403
[pr-396]: https://github.com/pakyow/pakyow/pull/396
[pr-393]: https://github.com/pakyow/pakyow/pull/393
[pr-389]: https://github.com/pakyow/pakyow/pull/389
[pr-387]: https://github.com/pakyow/pakyow/pull/387
[pr-385]: https://github.com/pakyow/pakyow/pull/385
[pr-384]: https://github.com/pakyow/pakyow/pull/384
[pr-383]: https://github.com/pakyow/pakyow/pull/383
[pr-379]: https://github.com/pakyow/pakyow/pull/379
[pr-378]: https://github.com/pakyow/pakyow/pull/378
[pr-377]: https://github.com/pakyow/pakyow/pull/377
[pr-376]: https://github.com/pakyow/pakyow/pull/376
[pr-373]: https://github.com/pakyow/pakyow/pull/373
[pr-372]: https://github.com/pakyow/pakyow/pull/372
[pr-371]: https://github.com/pakyow/pakyow/pull/371
[pr-370]: https://github.com/pakyow/pakyow/pull/370
[pr-369]: https://github.com/pakyow/pakyow/pull/369
[pr-368]: https://github.com/pakyow/pakyow/pull/368
[pr-367]: https://github.com/pakyow/pakyow/pull/367
[pr-366]: https://github.com/pakyow/pakyow/pull/366
[pr-365]: https://github.com/pakyow/pakyow/pull/365
[pr-364]: https://github.com/pakyow/pakyow/pull/364
[pr-363]: https://github.com/pakyow/pakyow/pull/363
[pr-361]: https://github.com/pakyow/pakyow/pull/361
[pr-359]: https://github.com/pakyow/pakyow/pull/359
[pr-358]: https://github.com/pakyow/pakyow/pull/358
[pr-357]: https://github.com/pakyow/pakyow/pull/357
[pr-352]: https://github.com/pakyow/pakyow/pull/352
[pr-351]: https://github.com/pakyow/pakyow/pull/351
[pr-349]: https://github.com/pakyow/pakyow/pull/349
[pr-343]: https://github.com/pakyow/pakyow/pull/343
[pr-340]: https://github.com/pakyow/pakyow/pull/340
[pr-330]: https://github.com/pakyow/pakyow/pull/330
[9ef221b]: https://github.com/pakyow/pakyow/commit/8eefc4ac6b6c04c0899471a12bc68e4edbc30f46
[244d4f6]: https://github.com/pakyow/pakyow/commit/244d4f6d2e5f18a38bf20cd4a4fcf8e3913137b3
[9ef221b]: https://github.com/pakyow/pakyow/commit/9ef221bcd671f37700d123fe852d0b316216f0d8
[59d983b]: https://github.com/pakyow/pakyow/commit/59d983b3cc31fd92d4ed8616f25c9a20d15da27b
[d410904]: https://github.com/pakyow/pakyow/commit/d4109047797e8e5d7f4233fe61a42ed472c96cd7
[3edf137]: https://github.com/pakyow/pakyow/commit/3edf1372869b4a49c4ad83cebc8eb55023f91278
[59e6efe]: https://github.com/pakyow/pakyow/commit/59e6efe42f1d6f5d48d15359d2e1a63bea9a0600
[787681d]: https://github.com/pakyow/pakyow/commit/787681dacbbd3ce79f6e38a5672749635903a85b

# v1.0.3 (unreleased)

  * `fix` **Hookable no longer makes including objects Enumerable**

    *Related links:*
    - [Pull Request #375][pr-375]

[pr-375]: https://github.com/pakyow/pakyow/pull/375

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
