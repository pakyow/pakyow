local function massive_redis_command(command, key, t)
  local i = 1
  local temp = {}

  while(i <= #t) do
    table.insert(temp, t[i + 1])
    table.insert(temp, t[i])

    if #temp >= 1000 then
      redis.call(command, key, unpack(temp))
      temp = {}
    end

    i = i + 2
  end

  if #temp > 0 then
    redis.call(command, key, unpack(temp))
  end
end

local function key_subscription_id(key_prefix, key_delimeter, subscription_id)
  return key_prefix .. key_delimeter .. "subscription:" .. subscription_id
end

local function key_subscribers_by_subscription_id(key_prefix, key_delimeter, subscription_id)
  return key_prefix .. key_delimeter .. "subscription:" .. subscription_id .. key_delimeter .. "subscribers"
end

local function key_source_for_subscription_id(key_prefix, key_delimeter, subscription_id)
  return key_prefix .. key_delimeter .. "subscription:" .. subscription_id .. key_delimeter .. "source"
end

local function key_subscription_ids_by_subscriber(key_prefix, key_delimeter, subscriber)
  return key_prefix .. key_delimeter .. "subscriber:" .. subscriber
end

local function key_subscription_ids_by_source(key_prefix, key_delimeter, source)
  return key_prefix .. key_delimeter .. "source:" .. source
end

local function subscription_ids_for_subscriber(key_prefix, key_delimeter, subscriber, min, max)
  return redis.call("zrangebyscore", key_subscription_ids_by_subscriber(key_prefix, key_delimeter, subscriber), min, max)
end

local function expire_subscription(key_prefix, key_delimeter, subscription_id)
  local subscription_key = key_subscribers_by_subscription_id(key_prefix, key_delimeter, subscription_id)

  -- only expire the subscription if it is not related to a non-expiring subscriber
  if redis.call("zcount", subscription_key, "+inf", "+inf") == 0 then
    local time_expire = redis.call("zrevrangebyscore", subscription_key, "+inf", 0, "WITHSCORES", "LIMIT", 0, 1)[2]

    if time_expire ~= "inf" then
      local source = redis.call("get", key_source_for_subscription_id(key_prefix, key_delimeter, subscription_id))
      redis.call("zadd", key_subscription_ids_by_source(key_prefix, key_delimeter, source), time_expire, subscription_id)

      redis.call("expireat", key_source_for_subscription_id(key_prefix, key_delimeter, subscription_id), time_expire + 1)
      redis.call("expireat", subscription_key, time_expire + 1)
      redis.call("expireat", key_subscription_id(key_prefix, key_delimeter, subscription_id), time_expire + 1)
    end
  end
end

local function persist_subscription(key_prefix, key_delimeter, subscription_id)
  local subscription_key = key_subscribers_by_subscription_id(key_prefix, key_delimeter, subscription_id)

  local source = redis.call("get", key_source_for_subscription_id(key_prefix, key_delimeter, subscription_id))
  redis.call("zadd", key_subscription_ids_by_source(key_prefix, key_delimeter, source), "+inf", subscription_id)

  redis.call("persist", key_source_for_subscription_id(key_prefix, key_delimeter, subscription_id))
  redis.call("persist", subscription_key)
  redis.call("persist", key_subscription_id(key_prefix, key_delimeter, subscription_id))
end
