---
title: Using endpoint states
---

It's often useful to style endpoints differently when a user is located at that endpoint. Pakyow handles this by rendering endpoints in one of two navigation states: current and active.

An endpoint is in a "current" state when its path fully matches the current url. These endpoints will receive a `ui-current` class.

When an endpoint path matches /part/ of the current url, the endpoint is considered "active". These endpoints will receive a `ui-active` class.
