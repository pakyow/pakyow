---
title: External Assets
---

Pakyow provides the following **application** config options for external assets:

* <a href="#assets.externals.fetch" name="assets.externals.fetch">`assets.externals.fetch`</a>: If `true`, external assets will be fetched at boot.
<span class="default">Default: `true`; `false` in *test* and *production*</span>

* <a href="#assets.externals.pakyow" name="assets.externals.pakyow">`assets.externals.pakyow`</a>: If `true`, Pakyow.js will be managed as an external asset.
<span class="default">Default: `true`</span>

* <a href="#assets.externals.provider" name="assets.externals.provider">`assets.externals.provider`</a>: Where to fetch external assets from.
<span class="default">Default: `"https://unpkg.com/"`</span>

* <a href="#assets.externals.path" name="assets.externals.path">`assets.externals.path`</a>: Where external assets live.
<span class="default">Default: `"{assets.packs.path}/vendor"`</span>
