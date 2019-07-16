---
title: Realtime
---

Pakyow provides the following **environment** config options for realtime:

* <a href="#realtime.server" name="realtime.server">`realtime.server`</a>: If `true`, the application manages its own WebSocket connections.
<span class="default">Default: `true`</span>

* <a href="#realtime.adapter" name="realtime.adapter">`realtime.adapter`</a>: What adapter to back realtime with.
<span class="default">Default: `:memory`; `:redis` in *production*</span>

* <a href="#realtime.adapter_options" name="realtime.adapter_options">`realtime.adapter_options`</a>: Options passed to the realtime adapter.
<span class="default">Default: `{}`; `redis_url: ENV["REDIS_URL"] || "redis://127.0.0.1:6379", redis_prefix: "pw"` in *production*</span>

Pakyow provides the following **application** config options for realtime:

* <a href="#realtime.path" name="realtime.path">`realtime.path`</a>: The path that WebSockets should connect to.
<span class="default">Default: `"pw-socket"`</span>

* <a href="#realtime.adapter_options" name="realtime.adapter_options">`realtime.adapter_options`</a>: Application specific options passed to the realtime adapter.
<span class="default">Default: `{}`; `redis_prefix: "pw/{app name}"` in *production*</span>
