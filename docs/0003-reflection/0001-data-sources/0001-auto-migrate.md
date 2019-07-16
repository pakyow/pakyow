---
title: Auto migrate
---

When you boot your project, Pakyow automatically creates a matching `messages` table in the database. The table is named after the `messages` data source and contains a column for every attribute defined on the source. This is the result of Pakyow's auto migrate feature.

Auto migrate works behind the scenes to keep your database structure in sync with your data sources. This is handy when you're developing because you don't have to stop and think too much about your database structure.

Once you finish a feature any changes to the database structure can be captured as physical database migrations that live in your project's codebase. Each migration consists of Ruby code that describes what changes need to be made to the database, whether it's creating a new table, adding a column, or changing a type.

Database migration files are created for you with the `pakyow db:finalize` command. One finalized migration file will be created for every change needed to put the database in the correct state for your project.
