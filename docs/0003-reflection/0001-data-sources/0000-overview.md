---
title: Data Sources
---

Data sources help model dynamic data stored in a database, defining aspects such as attributes, types, and associations. They also define actions for creating new data and queries that return results from the database. Data sources make up part of the backend of your project. The frontend doesn't interact directly with data sources, instead relying on backend actions and endpoints defined in controllers to move data to and from the frontend.

In this guide we'll focus on how Pakyow creates reflected data sources based on your frontend view templates. The next few guides that follow will walk you through adding layers of behavior on top of the data sources through actions and endpoints.

Ready? Let's get started!

When Pakyow finds a binding type in your view template, it creates a matching data source with all the attributes of the binding. For example, here's a view template that presents a message:

```html
<article binding="message">
  <h1 binding="subject">
    ...
  </h1>

  <p binding="content">
    ...
  </p>
</article>
```

In this case, Pakyow defines a `messages` data source with two attributes: `subject` and `content`. The name of the data source is simply a plural version of the binding type. Running the `info:sources` command prints out details about the reflected source:

```
:messages pakyow/reflection
  attribute :id,         :bignum
  attribute :content,    :string
  attribute :subject,    :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
```
