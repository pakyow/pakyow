---
name: Hooking Up Redis
desc: Setting up Redis for the data layer of the warmup project.
---

For simplicity, we'll use Redis as our data-store for this warmup project.
Pakyow already requires Redis in production (for some of the realtime bits), so
hooking into it is relatively straight-forward.

## Installing Redis

Make sure you have Redis installed on your local machine. If you use Homebrew
and OSX, it's easy:

```
brew install redis
```

If you don't use OSX or Homebrew, you can find appropriate installation
instructions in the [Redis Docs](http://redis.io/download).

## Accessing the Redis Connection

Pakyow Realtime already makes use of Redis, we just need to use the connection
that it creates. The most convenient way to do this is by creating a helper
method. Open `app/lib/helpers.rb` and replace the contents so that it looks like
the following:

```ruby
module Pakyow::Helpers
  def redis
    Pakyow::Realtime.redis
  end
end
```

## Configuring Redis for Production

Thinking ahead a bit, we'll need to access our production Redis instance once
deployed to Heroku. This is exposed via the `REDIS_URL` environment variable.
Open up `app/setup.rb` and replace the `configure :production` block with the
following production configuration code:

```ruby
configure :production do
  realtime.redis = { url: ENV['REDIS_URL'] }
end
```

That's all there is to it! We'll make use of this Redis connection in the next
section.
