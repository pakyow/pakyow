---
title: Subscriptions
---

Pakyow provides the following **environment** config options for data subscriptions:

* <a href="#data.subscriptions.adapter" name="data.subscriptions.adapter">`data.subscriptions.adapter`</a>: What adapter to back subscriptions with.
<span class="default">Default: `:memory`; `:redis` in *production*</span>

* <a href="#data.subscriptions.adapter_options" name="data.subscriptions.adapter_options">`data.subscriptions.adapter_options`</a>: Options passed to the subscription adapter.
<span class="default">Default: `{}`; `redis_url: ENV["REDIS_URL"] || "redis://127.0.0.1:6379", redis_prefix: "pw"` in *production*</span>
