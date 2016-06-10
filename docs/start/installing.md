---
name: Download / Installing
desc: Installing Pakyow for local development.
---

Pakyow is easy to install, but needs a modern version of
the [Ruby](http://www.ruby-lang.org) programming language.
You can check the state of your system by running this
command in your terminal:

```
bash <(curl -s https://raw.githubusercontent.com/pakyow/pakyow-deps/master/check.sh)
```

## Install Ruby

Mac users:
  - Mac OS X comes with Ruby, but it probably isn't new enough.
  - Install [Homebrew](http://brew.sh/)
  - Then install Ruby:

  `brew install ruby`

Linux users:
  - Most Linux distros come with Ruby, but they may not be new enough.
  - For Debian/Ubuntu/Mint:

  `sudo apt-get update; sudo apt-get install ruby;`
  - For CentOS/Red Hat/Fedora:

  `sudo yum install ruby`

Windows users:
- Use [RubyInstaller](http://rubyinstaller.org/)

## Install Pakyow

Once everything checks out, install Pakyow via RubyGems:

```
gem install pakyow
```

That's it! Pakyow is installed and ready to rumble.

## Additional Ways to Install
Here are some additional links that might be helpful:

  - [Ruby Installation](https://www.ruby-lang.org/en/documentation/installation/)
  - [RubyGems Download](https://rubygems.org/pages/download)
