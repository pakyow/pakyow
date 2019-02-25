local key_prefix = ARGV[1]
local key_delimeter = ARGV[2]
local subscriber = ARGV[3]
local subscription_id = ARGV[4]
local subscription_string = ARGV[5]
local source = ARGV[6]
local now = ARGV[7]

local expiry = "+inf"

-- determine if the subscriber is expiring
local ttl = redis.call("ttl", key_subscription_ids_by_subscriber(key_prefix, key_delimeter, subscriber))

if ttl > -1 then
  expiry = now + ttl
end

-- store the subscription
redis.call("set", key_subscription_id(key_prefix, key_delimeter, subscription_id), subscription_string)

-- add the subscription to the subscriber's set
redis.call("zadd", key_subscription_ids_by_subscriber(key_prefix, key_delimeter, subscriber), expiry, subscription_id)

-- add the subscriber to the subscription's set
redis.call("zadd", key_subscribers_by_subscription_id(key_prefix, key_delimeter, subscription_id), expiry, subscriber)

-- add the subscription to the source's set
redis.call("zadd", key_subscription_ids_by_source(key_prefix, key_delimeter, source), "+inf", subscription_id)

-- define what source the subscription is for
redis.call("set", key_source_for_subscription_id(key_prefix, key_delimeter, subscription_id), source)

if ttl > -1 then
  expire_subscription(key_prefix, key_delimeter, subscription_id)
else
  persist_subscription(key_prefix, key_delimeter, subscription_id)
end
