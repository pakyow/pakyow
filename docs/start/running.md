---
name: Running the Server
desc: Starting the Pakyow server.
---

Pakyow includes a tool for running projects locally during development. To start the
server, run the following command in terminal from the main directory of your project:

```
cd your-app-name-here
bundle exec pakyow server
```

You should see some ouput similar to this:

```
Puma 2.7.1 starting...
* Min threads: 0, max threads: 16
* * Environment: development
* * Listening on tcp://0.0.0.0:3000
```

Navigate to [http://localhost:3000](http://localhost:3000) and you should find your app running!
