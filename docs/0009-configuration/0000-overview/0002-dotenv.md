---
title: Using Dotenv
---

Dotenv files are the standard way to manage secret values--such as an api key--or values specific to an individual development environment--such as a database connection string. Projects are generated with the [dotenv integration](https://github.com/pakyow/pakyow/blob/e4ee72edc6b8c0db417b4c7540ce6c209f2c12ec/lib/pakyow/integrations/dotenv.rb) by default. When the project boots up, values from a `.env` file located in the project root are loaded into Ruby's `ENV` constant.

Here's an example `.env` file that contains a single key/value pair:

```bash
SETTING=value
```

These values can now be used to replace the hardcoded values in the configure blocks:

```ruby
Pakyow.app do
  configure do
    config.setting = ENV["SETTING"]
  end
end
```

Here are some recommendations when using dotenv:

* Don't keep dotenv files in version control. This is no better than hardcoding the values.
* Create a `.env.example` file with necessary keys and values and a brief explanation of how they're used. Do keep this file in version control as the canonical reference that other developers can use.

# Environment-Specific Dotfiles

The dotenv integration will also load any environment-specific dotfiles that are present. For example, values from `.env.test` will be loaded when booting Pakyow in the `test` environment.
