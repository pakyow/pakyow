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
      console.log("connected");
    }

    this.connection.onclose = () => {
      this.connected = false;
      this.reconnect();
    }

    this.connection.onmessage = (evt) => {
      var payload = JSON.parse(evt.data).payload;
      console.log("onmessage", payload);
      for (let cb of this.subscriptions[payload.channel] || []) {
        cb(payload);
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

  subscribe (channel, cb) {
    if (!this.subscriptions[channel]) {
      this.subscriptions[channel] = [];
    }

    this.subscriptions[channel].push(cb);
  }
}
