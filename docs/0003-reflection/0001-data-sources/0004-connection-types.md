---
title: Connection types for data sources
---

When Pakyow creates a reflected data source, it assigns one of two connection types: `default` or `memory`. The `default` connection is used for data that is long-lived and should continue to exist even if the application restarts. The `memory` connection is used for less important data that can come and go as needed. You can think of the `memory` connection as a cache that can be queried with SQL.

Pakyow assigns a connection type to a source based on its perceived intent. If a form is defined for a binding type, Pakyow assumes that the data should be persistent. Data sources with a related form are assigned the `default` connection, usually pointing to a local SQLite file or a Postgres database.

On the other hand, binding types that don't have a form are assigned the `memory` connection. Pakyow assumes that these types will be used for temporary data, or data that is loaded every time the project boots. Pakyow automatically creates an in-memory SQLite database for memory sources.

These decisions make good default conventions, but your project may not follow these rules at all times. If you need to make an exception, you can manually assign a connection type to any data source. We'll cover how in the next section on customization.
