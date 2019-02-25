local key_prefix = ARGV[1]
local key_delimeter = ARGV[2]
local subscriber = ARGV[3]

redis.call("persist", key_subscription_ids_by_subscriber(key_prefix, key_delimeter, subscriber))

local subscription_ids = subscription_ids_for_subscriber(key_prefix, key_delimeter, subscriber, 0, "+inf")

local i = 1
while(i <= #subscription_ids) do
  local subscription_id = subscription_ids[i]
  redis.call("zadd", key_subscribers_by_subscription_id(key_prefix, key_delimeter, subscription_id), "+inf", subscriber)
  persist_subscription(key_prefix, key_delimeter, subscription_id)
  i = i + 1
end
