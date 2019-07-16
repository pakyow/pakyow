---
title: Inspecting the reflection
---

Reflection doesn't generate code, instead it attaches behavior dynamically to your project when it boots. You can see everything reflection has attached to your project with the following commands:

**Reflected Actions & Endpoints:**

```
pakyow info:endpoints

:messages_create          POST  /messages                      pakyow/reflection
:messages_replies_create  POST  /messages/:message_id/replies  pakyow/reflection
:messages_show            GET   /messages/:id                  pakyow/reflection
:root                     GET   /                              pakyow/reflection
```

**Reflected Data Sources:**

```
pakyow info:sources

:messages pakyow/reflection
  has_many :replies

  attribute :id,         :bignum
  attribute :content,    :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

:replies pakyow/reflection
  belongs_to :message

  attribute :id,         :bignum
  attribute :message_id, :bignum
  attribute :content,    :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
```

Reflected parts are tagged with `pakyow/reflection`.
