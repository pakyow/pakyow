---
name: Creating a Project
desc: Creating a new Pakyow project.
---

Pakyow includes a tool for generating new projects. Run this
command from your terminal:

```
pakyow new enter-your-app-name-here
```

You should see some output similar to this:

```
Generating project: my-app
Running `bundle install` in my-app
Fetching gem metadata from https://rubygems.org/...........
Resolving dependencies...
Using addressable 2.3.6
Using bundler 1.7.3
Using css_parser 1.3.5
Using htmlentities 4.3.3
Using mime-types 2.4.3
Using mail 2.6.3
Using mini_portile 0.6.2
Using nokogiri 1.6.5
Using pakyow-support 0.9.1
Using rack 1.6.0
Using pakyow-core 0.9.1
Using pakyow-presenter 0.9.1
Using premailer 1.8.2
Using pakyow-mailer 0.9.1
Using pakyow-rake 0.9.1
Using pakyow 0.9.1
Using puma 2.10.2
Your bundle is complete!
Use `bundle show [gemname]` to see where a bundled gem is installed.
Done! Run `cd my-app; bundle exec pakyow server` to get started!
```

Pakyow has generated a project in a new directory and installed
all necessary dependencies; you're ready to go!
