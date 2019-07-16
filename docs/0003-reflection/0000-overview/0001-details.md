---
title: How it works
---

Reflection works by building an understanding of your application from the semantic intent in your view templates, such as data bindings. When Reflection encounters a binding type with one or more attributes, a matching data source is created for storing data in the database. The data source is exposed back to the frontend view template through endpoints, automatically presenting data from the database in your views.

Reflection also looks for any forms defined for the binding type, creating actions that connect each form to its reflected data source. Reflected actions handle everything from verifying and validating the submitted data, presenting errors back to the user, and saving data to the database.

There's a lot more to cover, but we'll get to the details in next few guides.
