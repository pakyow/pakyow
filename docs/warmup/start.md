---
name: Get Moving
desc: Taking your first steps with Pakyow.
---

First, please make sure Pakyow is installed on your local system. You can find
[details here](/docs/start/installing).

Pakyow ships with a few command-line tools that help you generate and manage
your projects. These tools make creating a new project really easy. Open up a
terminal prompt and create a new project:

```
pakyow new warmup
```

You should see output similar to this:

```
Generating project: warmup
Running `bundle install` in /Users/bryanp/Desktop/warmup
Fetching gem metadata from https://rubygems.org/...........
Fetching version metadata from https://rubygems.org/...
Fetching dependency metadata from https://rubygems.org/..
Resolving dependencies...
Using rake 10.4.2
Using addressable 2.3.8
Using bundler 1.10.6
Using concurrent-ruby 0.9.2
Using css_parser 1.3.7
Using diff-lcs 1.2.5
Using htmlentities 4.3.4
Using mime-types 2.6.2
Using mail 2.6.3
Using mini_portile 0.6.2
Using nokogiri 1.6.6.2
Using pakyow-support 0.10.1
Using rack 1.6.4
Using pakyow-core 0.10.1
Using pakyow-presenter 0.10.1
Using premailer 1.8.6
Using pakyow-mailer 0.10.1
Using pakyow-rake 0.10.1
Using redis 3.2.1
Using websocket_parser 1.0.0
Using pakyow-realtime 0.10.1
Using pakyow-test 0.10.1
Using pakyow-ui 0.10.1
Using pakyow 0.10.1
Using puma 2.15.3
Using rspec-support 3.4.0
Using rspec-core 3.4.0
Using rspec-expectations 3.4.0
Using rspec-mocks 3.4.0
Using rspec 3.4.0
Bundle complete! 4 Gemfile dependencies, 30 gems now installed.
Use `bundle show [gemname]` to see where a bundled gem is installed.
Done! Run `cd warmup; bundle exec pakyow server` to get started!
```

Pakyow creates the entire project structure for us, allowing us to get right to
work. Move into the new `warmup` directory by typing `cd warmup` and then start
the server with the following command:

```
bundle exec pakyow server
```

Go to [localhost:3000](http://localhost:3000) in a web browser to see your
project running!
