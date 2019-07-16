---
title: Customizing reflected data sources
---

Pakyow makes it possible to customize reflected data sources to handle cases that fall outside of what reflection is designed for. To customize a data source, create a data source in the `backend/sources` folder:

```ruby
source :messages do
  attribute :view_count, :integer
end
```

Reflection will extend the data source with attributes and associations it discovers, but won't override any behavior you define yourself. To set a custom type for a reflected attribute, just define the attribute with the type that you want:

```ruby
source :messages do
  attribute :some_reflected_attribute, :boolean
end
```
