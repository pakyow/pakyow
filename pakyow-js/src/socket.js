export default class {
  constructor(options = {}) {
    this.host = options.host || window.location.hostname;
    this.port = options.port || window.location.port;
    this.protocol = options.protocol || window.location.protocol;
    this.id = options.id || document.querySelector("meta[name='pw-connection-id']").content;
    this.endpoint = options.endpoint || document.querySelector("meta[name='pw-endpoint']").content;

    this.reconnectTimeout = this.currentReconnectTimeout = 500;
    this.reconnectDecay = 1.25;

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

      pw.broadcast("pw:socket:connected");
    }

    this.connection.onclose = () => {
      pw.broadcast("pw:socket:closed");

      this.connected = false;
      this.reconnect();
    }

    this.connection.onmessage = (event) => {
      var payload = JSON.parse(event.data).payload;
      for (let callback of this.subscriptions[payload.channel] || []) {
        callback(payload);
      }
    }
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

  subscribe (channel, callback) {
    if (!this.subscriptions[channel]) {
      this.subscriptions[channel] = [];
    }

    this.subscriptions[channel].push(callback);
  }
}
