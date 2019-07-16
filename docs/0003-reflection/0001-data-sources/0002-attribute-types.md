---
title: Attribute types
---

Each attribute on a data source has a type. Let's inspect the source defined above:

```
:messages pakyow/reflection
  attribute :id,         :bignum
  attribute :content,    :string
  attribute :subject,    :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
```

Both attributes are `string` types. Pakyow assumes all binding attributes to be strings by default, but there are a few cases where a more specific type is chosen.

## Inferred types from names

In some cases the attribute type can be pulled from the name of the attribute itself. One such case is with date attributes. A convention in Pakyow is to name datetime fields like this:

```
{attribute}_at
```

Data sources use this convention to define `created_at` and `updated_at` attributes that track when a record was created and updated. When Pakyow encounters a binding attribute with an `_at` suffix, it defines the attribute as a `datetime` type in the data source.

## Inferred types from form fields

Attribute types can also be inferred from form fields. There are currently two types that will be defined this way: `datetime` and `decimal`. Attributes are assigned the `datetime` type when defined on any of these form fields:

```html
<input type="datetime">
<input type="datetime-local">
<input type="time">
```

Attributes are assigned the `decimal` type when defined on any of these form fields:

```html
<input type="number">
<input type="range">
```

## Specifying other types

Not all data types can be inferred from the attribute name or defined on a form field. The best way to handle these cases is to extend the reflected data source and definethe exact types that you want. We'll talk about extending data sources later in this guide.
