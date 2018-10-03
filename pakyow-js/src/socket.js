export default class {
  constructor(options = {}) {
    this.host = options.host || window.location.hostname;
    this.port = options.port || window.location.port;
    this.protocol = options.protocol || window.location.protocol;
    this.id = options.id || document.querySelector("meta[name='pw-connection-id']").content;
    this.endpoint = options.endpoint || document.querySelector("meta[name='pw-endpoint']").content;

    this.reconnectTimeout = this.currentReconnectTimeout = 500;
    this.reconnectDecay = 1.25;

    this.heartbeat = 30000;

    // Server state associated with a socket is cleaned up after 60 seconds. When
    // this happens, clients should either ask the user to reload, or reload the
    // page themselves if it can do so in a non-destructive way. Stale sockets
    // will broadcast a `pw:socket:connected:stale` message upon reconnecting.
    //
    // Note that a socket becomes stale 5 seconds early to account for the fact
    // that server-side state is created ahead of the socket connecting.
    //
    this.socketBecomesStaleIn = 55000;

    this.subscriptions = {};

    this.connect();
  }

  connect() {
    if (!this.id) {
      return;
    }

    this.connection = new WebSocket(this.websocketUrl());

    this.connection.onopen = () => {
      this.currentReconnectTimeout = this.reconnectTimeout;
      this.connected = true;

      if (this.disconnectedAt && (this.timeInMilliseconds() - this.disconnectedAt) > this.socketBecomesStaleIn) {
        pw.broadcast("pw:socket:connected:stale");
      } else {
        pw.broadcast("pw:socket:connected");
      }

      this.disconnectedAt = null;
    }

    this.connection.onclose = () => {
      if (this.connected) {
        pw.broadcast("pw:socket:closed");
        this.connected = false;
        this.disconnectedAt = this.timeInMilliseconds();
      }

      this.reconnect();
    }

    this.connection.onmessage = (event) => {
      var payload = JSON.parse(event.data).payload;
      for (let callback of this.subscriptions[payload.channel] || []) {
        callback(payload);
      }
    }

    setInterval(() => {
      this.beat();
    }, this.heartbeat);
  }

  websocketUrl() {
    return this.endpoint + "?id=" + encodeURIComponent(this.id);
  }

  reconnect() {
    setTimeout(() => {
      this.currentReconnectTimeout *= this.reconnectDecay;
      this.connect();
    }, this.currentReconnectTimeout);
  }

  beat() {
    this.connection.send("beat");
  }

  subscribe (channel, callback) {
    if (!this.subscriptions[channel]) {
      this.subscriptions[channel] = [];
    }

    this.subscriptions[channel].push(callback);
  }

  timeInMilliseconds() {
    return (new Date).getTime();
  }
}
