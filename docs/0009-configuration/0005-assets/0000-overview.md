---
title: Assets
---

Pakyow provides the following **application** config options for assets:

* <a href="#assets.cache" name="assets.cache">`assets.cache`</a>: If `true`, cache headers will be set on responses to asset requests.
<span class="default">Default: `false`; `true` in *production*</span>

* <a href="#assets.fingerprint" name="assets.fingerprint">`assets.fingerprint`</a>: If `true`, assets will be fingerprinted based on their contents.
<span class="default">Default: `false`; `true` in *production*</span>

* <a href="#assets.minify" name="assets.minify">`assets.minify`</a>: If `true`, assets that support minification will be minified.
<span class="default">Default: `false`; `true` in *production*</span>

* <a href="#assets.process" name="assets.process">`assets.process`</a>: If `true`, assets will be processed at request time.
<span class="default">Default: `true`; `false` in *production*</span>

* <a href="#assets.public" name="assets.public">`assets.public`</a>: If `true`, any file found in `public_path` will be served.
<span class="default">Default: `true`</span>

* <a href="#assets.silent" name="assets.silent">`assets.silent`</a>: If `true`, asset requests will not be logged.
<span class="default">Default: `true`; `false` in *production*</span>

* <a href="#assets.prefix" name="assets.prefix">`assets.prefix`</a>: Root path that assets are requested from.
<span class="default">Default: `"/assets"`</span>

* <a href="#assets.public_path" name="assets.public_path">`assets.public_path`</a>: Where to serve public.
<span class="default">Default: `"{root}/public"`</span>

* <a href="#assets.compile_path" name="assets.compile_path">`assets.compile_path`</a>: Where assets will be compiled to.
<span class="default">Default: `"{root}/public"`</span>

* <a href="#assets.path" name="assets.path">`assets.path`</a>: Where to find assets.
<span class="default">Default: `"{presenter.path}/assets"`</span>

* <a href="#assets.types" name="assets.types">`assets.types`</a>: All of the supported asset types.
<span class="default">Default: `{ av: [".webm", ".snd", ".au", ".aiff", ".mp3", ".mp2", ".m2a", ".m3a", ".ogx", ".gg", ".oga", ".midi", ".mid", ".avi", ".wav", ".wave", ".mp4", ".m4v", ".acc", ".m4a", ".flac"], data: [".json", ".xml", ".yml", ".yaml"], fonts: [".eot", ".otf", ".ttf", ".woff", ".woff2"], images: [".ico", ".bmp", ".gif", ".webp", ".png", ".jpg", ".jpeg", ".tiff", ".tif", ".svg"], scripts: [".js"], styles: [".css", ".sass", ".scss"] }`</span>
