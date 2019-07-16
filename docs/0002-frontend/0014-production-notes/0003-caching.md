---
title: Caching assets
---

When Pakyow fulfills a request for a fingerprinted asset, it responds with several cache headers that tell the browser how to cache the asset.

Here's a list of headers that are set:

| Header        | Value                                                |
|---------------|------------------------------------------------------|
| Age           | The number of seconds since the asset was modified.  |
| Cache-Control | `public, max-age=31536000`; tells the browser to cache the asset for one year. |
| Vary          | `Accept-Encoding`; [read more about this header &rarr;](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Vary) |
| Last-Modified | The date the asset was last modified.                |

These settings are appropriate for most applications.


## Disable caching

Caching can be disabled by setting the `assets.cache` configuration option for the production environment:

<div class="filename">
  config/application.rb
</div>

```ruby
Pakyow.app do
  configure :production do
    config.assets.cache = false
  end
end
```
