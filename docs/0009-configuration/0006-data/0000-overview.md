---
title: Data
---

Pakyow provides the following **environment** config options for data:

* <a href="#data.silent" name="data.silent">`data.silent`</a>: If `true`, logging is disabled across all data sources.
<span class="default">Default: `true`</span>

* <a href="#data.auto_migrate" name="data.auto_migrate">`data.auto_migrate`</a>: If `true`, data sources will be auto migrated on boot.
<span class="default">Default: `true`; `false` in *production*</span>

* <a href="#data.auto_migrate_always" name="data.auto_migrate_always">`data.auto_migrate_always`</a>: Array of connection names that will always be auto migrated.
<span class="default">Default: `[:memory]`</span>

* <a href="#data.default_adapter" name="data.default_adapter">`data.default_adapter`</a>: Name of the adapter to use when unspecified in a data source.
<span class="default">Default: `:sql`</span>

* <a href="#data.default_connection" name="data.default_connection">`data.default_connection`</a>: Name of the connection to use when unspecified in a data source.
<span class="default">Default: `:default`</span>

* <a href="#data.migration_path" name="data.migration_path">`data.migration_path`</a>: Where database migration files live.
<span class="default">Default: `"{root}/database/migrations"`</span>
