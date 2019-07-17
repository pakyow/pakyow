# UNRELEASED

  * [fixed] Issue causing data subscriptions to never be expired for a web socket connection
  * [changed] Let websocket instances manage their own heartbeats, rather than the websocket server
  * [changed] Send heartbeats every second from websocket instances
    * This and the change prior seem to resolve intermittent timeouts on production

# 1.0

  * Hello, Web
