---
title: Installing Pakyow
---

Pakyow projects are developed locally and deployed to a server when it's time to show the project to others. In this guide we'll walk through getting a local development environment setup so you can get to building. Since Pakyow has few outside dependencies, this shouldn't take too long.

First, Pakyow needs a modern version of [Ruby](https://www.ruby-lang.org/en/). To check if Ruby is already installed on your system, open a terminal and run this command:

```
ruby -v
```

If Ruby is installed, you should see output that looks like this:

```
ruby 2.6.3p62
```

*Pakyow is compatible with Ruby 2.5 and later.* If you have an older version of Ruby installed, or you're missing Ruby altogether, move on to [Installing Ruby](#installing-ruby). Otherwise, run this command to install Pakyow:

```
gem install pakyow
```

If the command succeeds, you're ready to go!

> [callout] Ruby & Pakyow installed? Next, [generate your project](doc:hello/installing/generate).
