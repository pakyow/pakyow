---
title: Presenting a custom dataset
---

Reflection lets you define custom datasets for bindings. This is useful when you want to override the default dataset, which is either all the data for a binding or, in the case of show endpoints, a specific object for the binding.

Building on the example from the previous section, we can specify the dataset to use for each instance of the binding. We'll present a dataset with recent messages in the first binding, and an alphabetically ordered dataset in the second binding.

Here's what the view template looks like with defined datasets:

```html
<h1>
  Most recent messages:
</h1>

<article binding="message:recent" dataset="query: all; order: created_at(desc)">
  <p binding="content">
    message content goes here
  </p>
</article>

<h1>
  Messages in alphabetical order:
</h1>

<article binding="message:alphabetical" dataset="query: all; order: content(asc)">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Each dataset defines two aspects: 1) the query to perform and 2) how to order results. There's also third option for limiting the dataset. We'll cover each of these more below.

## Dataset queries

Queries are defined on the data source that matches the binding. All data sources define an `all` query by default that returns all of the results from the database. You can define additional queries by defining it on the data source:

```ruby
source :messages do
  def important
    where(build("content like ?", "sos"))
  end
end
```

This query returns results that contain "sos" somewhere in their content. The new `important` query can be used in a from template like this:

```html
<h1>
  Important messages:
</h1>

<article binding="message" dataset="query: important">
  <p binding="content">
    message content goes here
  </p>
</article>
```

* Read more about queries for backend data sources &rarr;

## Dataset ordering

Datasets can be ordered by any of their attributes, in ascending or descending order. Every aspect of ordering can be expressed in the view template. For example, here's how you would order a dataset by `created_at` date availbale on every data source:

```html
<article binding="message" dataset="order: created_at">
  <p binding="content">
    message content goes here
  </p>
</article>
```

By default, datasets are ordered in ascending order. If you want to put the most recent messages at the top, you would specify descending order in the view template:

```html
<article binding="message" dataset="order: created_at(desc)">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Datasets can also be ordered by multiple attributes:

```html
<article binding="message" dataset="order: created_at(desc), content">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Here the dataset will first be ordered by creation date (most recent first), then alphabetically based on the content of each message.

## Dataset limiting

Datasets can be limited to a specific number of results using the `limit` keyword:

```html
<article binding="message" dataset="limit: 10">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Here, only 10 messages will be presented in this view template.
