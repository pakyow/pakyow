pw.define("socket", {
  appear() {
    this.reconnectTimeout = this.currentReconnectTimeout = 500;
    this.reconnectDecay = 1.25;

    this.reconnecting = false;

    this.heartbeat = 30000;

    this.connect();
  },

  disappear() {
    pw.broadcast("pw:socket:disappeared", this);
    this.connection.onclose = null;
    this.connection.close();
    this.connected = false;
  },

  connect() {
    if (!this.config.endpoint) {
      return;
    }

    this.connection = new WebSocket(this.config.endpoint);

    this.connection.onopen = () => {
      pw.broadcast("pw:socket:connected", this);
      this.currentReconnectTimeout = this.reconnectTimeout;
      this.connected = true;
    }

    this.connection.onclose = () => {
      if (this.connected) {
        pw.broadcast("pw:socket:closed", this);
        this.connected = false;
      }

      this.reconnect();
    }

    this.connection.onmessage = (event) => {
      var payload = JSON.parse(event.data).payload;
      pw.broadcast("pw:socket:message:" + payload.channel, payload.message);
    }

    if (!this.reconnecting) {
      setInterval(() => {
        this.beat();
      }, this.heartbeat);

      pw.wakes.push(() => {
        this.beat();
      });
    }
  },

  reconnect() {
    this.reconnecting = true;

    setTimeout(() => {
      this.currentReconnectTimeout *= this.reconnectDecay;
      this.connect();
    }, this.currentReconnectTimeout);
  },

  beat() {
    this.connection.send("beat");
  }
});
