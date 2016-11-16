---
name: Setup & Running
desc: Setting up and running the Pakyow environment.
---

After one or more endpoints has been [mounted](/docs/environment/mounting), the
environment can be booted. Booting is a two-step process that consists of first
setting up the environment, and then running it.

## Environment Setup

Before the environment can be started, it must first be setup. Setup involves
configuring the environment and mounting each registered endpoint within it.
Here's how you would setup the environment to run in development mode:

```ruby
Pakyow.setup(mode: :development)
```

Note that if the `mode` argument is unspecified, Pakyow will default to the
`mode.default` [config option](/docs/environment/configuration).

## Running

Once setup is complete, the environment can be run. Running the environment
involves starting up the application server on a host and a port. Here's how you
would setup and run the environment on port 2001:

```ruby
Pakyow.setup.run(port: 2001)
```

The `host` and `server` can also be specified as arguments to the `run` method.
If unspecified, Pakyow will default to the `server.*` [config
options](/docs/environment/configuration).
