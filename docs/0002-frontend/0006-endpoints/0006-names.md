---
title: Inspecting endpoint names
---

Endpoint names are part of the implicit contract that exists between the frontend and backend of an application. To see a full list of endpoints along with their names, run the `info:endpoints` command:

```
pakyow info:endpoints
:messages_create          POST  /messages                      pakyow/reflection
:messages_replies_create  POST  /messages/:message_id/replies  pakyow/reflection
:messages_show            GET   /messages/:id                  pakyow/reflection
:root                     GET   /                              pakyow/reflection
```
