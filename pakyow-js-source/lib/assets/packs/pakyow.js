(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
	typeof define === 'function' && define.amd ? define(factory) :
	(global.pw = factory());
}(this, (function () { 'use strict';

var version = "1.0.0.beta1";

var inits = [];

function ready (callback) {
  if (document.readyState === "interactive" || document.readyState === "complete") {
    callback();
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
}

function send (url) {
  var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

  if (!options.cache) {
    url += (-1 == url.indexOf("?") ? "?" : "&") + "_=" + new Date().getTime();
  }

  var method = options.method || "GET";

  var xhr = new XMLHttpRequest();
  xhr.open(method, url);
  xhr.setRequestHeader("Pw-Ui", pw.version);

  for (var header in options.headers || {}) {
    xhr.setRequestHeader(header, options.headers[header]);
  }

  xhr.onreadystatechange = function () {
    if (xhr.readyState === 4) {
      var status = xhr.status;

      if (status >= 200 && (status < 300 || status === 304)) {
        if (options.success) {
          options.success(xhr.responseText);
        }

        pw.broadcast("pw:request:succeeded");
      } else {
        if (options.error) {
          options.error(xhr, xhr.statusText);
        }

        pw.broadcast("pw:request:failed");
      }

      if (options.complete) {
        options.complete(xhr);
      }

      pw.broadcast("pw:request:completed");
    }
  };

  if (method !== "GET") {
    var $token = document.querySelector("meta[name='pw-authenticity-token']");
    var $param = document.querySelector("meta[name='pw-authenticity-param']");

    if ($token && $param) {
      if (!options.data || !options.data[$param.getAttribute("content")]) {
        if (!options.data) {
          options.data = {};
        }

        options.data[$param.getAttribute("content")] = $token.getAttribute("content");
      }
    }
  }

  var data;
  if (options.data) {
    xhr.setRequestHeader("Content-Type", "application/json");
    data = JSON.stringify(options.data);
  }

  xhr.send(data);

  pw.broadcast("pw:request:dispatched");

  return xhr;
}

function define (name, object) {
  var component = pw.Component.create();
  Object.getOwnPropertyNames(object).forEach(function (method) {
    component.prototype[method] = object[method];
  });

  pw.Component.register(name, component);
}

function broadcast (channel, payload) {
  pw.Component.broadcast(channel, payload);
}

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) {
  return typeof obj;
} : function (obj) {
  return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj;
};

var classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
};

var createClass = function () {
  function defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  return function (Constructor, protoProps, staticProps) {
    if (protoProps) defineProperties(Constructor.prototype, protoProps);
    if (staticProps) defineProperties(Constructor, staticProps);
    return Constructor;
  };
}();

var components = {};
var instances = [];
var broadcasts = {};
var observer;

var _class = function () {
  function _class() {
    classCallCheck(this, _class);
  }

  createClass(_class, null, [{
    key: "register",
    value: function register(name, component) {
      components[name] = component;
    }
  }, {
    key: "init",
    value: function init(node) {
      var _this = this;

      if (!observer) {
        observer = new MutationObserver(function (evt) {
          if (evt[0].addedNodes) {
            var _iteratorNormalCompletion = true;
            var _didIteratorError = false;
            var _iteratorError = undefined;

            try {
              for (var _iterator = evt[0].addedNodes[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
                var _node = _step.value;

                if (_node.tagName && _node.dataset.ui) {
                  _this.componentFromView(new pw.View(_node));
                }
              }
            } catch (err) {
              _didIteratorError = true;
              _iteratorError = err;
            } finally {
              try {
                if (!_iteratorNormalCompletion && _iterator.return) {
                  _iterator.return();
                }
              } finally {
                if (_didIteratorError) {
                  throw _iteratorError;
                }
              }
            }
          }

          if (evt[0].removedNodes) {
            var _loop = function _loop(_node2) {
              var component = instances.find(function (component) {
                return component.view.node === _node2;
              });

              if (component) {
                component.channels.forEach(function (channel) {
                  component.ignore(channel);
                });

                instances.splice(instances.indexOf(component), 1);
              }
            };

            var _iteratorNormalCompletion2 = true;
            var _didIteratorError2 = false;
            var _iteratorError2 = undefined;

            try {
              for (var _iterator2 = evt[0].removedNodes[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
                var _node2 = _step2.value;

                _loop(_node2);
              }
            } catch (err) {
              _didIteratorError2 = true;
              _iteratorError2 = err;
            } finally {
              try {
                if (!_iteratorNormalCompletion2 && _iterator2.return) {
                  _iterator2.return();
                }
              } finally {
                if (_didIteratorError2) {
                  throw _iteratorError2;
                }
              }
            }
          }
        });

        observer.observe(document.body, { childList: true });
      }

      var _iteratorNormalCompletion3 = true;
      var _didIteratorError3 = false;
      var _iteratorError3 = undefined;

      try {
        for (var _iterator3 = new pw.View(node).query("*[data-ui]")[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
          var view = _step3.value;

          this.componentFromView(view);
        }
      } catch (err) {
        _didIteratorError3 = true;
        _iteratorError3 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion3 && _iterator3.return) {
            _iterator3.return();
          }
        } finally {
          if (_didIteratorError3) {
            throw _iteratorError3;
          }
        }
      }
    }
  }, {
    key: "componentFromView",
    value: function componentFromView(view) {
      if (!instances.find(function (component) {
        return component.view.node === view.node;
      })) {
        var object = components[view.node.dataset.ui] || this.create();
        var instance = new object(view, this.parseConfig(view.node.dataset.config));
        instances.push(instance);
        instance.ready();
      }
    }
  }, {
    key: "broadcast",
    value: function broadcast(channel, payload) {
      var _iteratorNormalCompletion4 = true;
      var _didIteratorError4 = false;
      var _iteratorError4 = undefined;

      try {
        for (var _iterator4 = (broadcasts[channel] || [])[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {
          var tuple = _step4.value;

          tuple[0].trigger(channel, payload);
        }
      } catch (err) {
        _didIteratorError4 = true;
        _iteratorError4 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion4 && _iterator4.return) {
            _iterator4.return();
          }
        } finally {
          if (_didIteratorError4) {
            throw _iteratorError4;
          }
        }
      }
    }
  }, {
    key: "parseConfig",
    value: function parseConfig(configString) {
      if (typeof configString === "undefined") {
        return {};
      }

      return configString.split(";").reduce(function (config, option) {
        var key_value = option.trim().split(":");
        config[key_value[0].trim()] = key_value[1].trim();
        return config;
      }, {});
    }
  }, {
    key: "clearObserver",
    value: function clearObserver() {
      if (observer) {
        observer.disconnect();
        observer = null;
      }
    }
  }, {
    key: "create",
    value: function create() {
      var component = function component(view) {
        var config = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

        this.view = view;
        this.node = view.node;
        this.config = config;
        this.channels = [];
      };

      component.prototype.ready = function () {
        // intentionally empty
      };

      component.prototype.listen = function (channel, callback) {
        var _this2 = this;

        this.view.node.addEventListener(channel, function (evt) {
          callback.call(_this2, evt.detail);
        });

        if (!broadcasts[channel]) {
          broadcasts[channel] = [];
        }

        broadcasts[channel].push([this, callback]);
        this.channels.push(channel);
      };

      component.prototype.ignore = function (channel) {
        var _this3 = this;

        broadcasts[channel].filter(function (tuple) {
          return tuple[0].view.node === _this3.view.node;
        }).forEach(function (tuple) {
          _this3.view.node.removeEventListener(channel, tuple[1]);
          broadcasts[channel].splice(broadcasts[channel].indexOf(tuple), 1);
        });

        this.channels.splice(this.channels.indexOf(channel), 1);
      };

      component.prototype.trigger = function (channel, payload) {
        this.view.node.dispatchEvent(new CustomEvent(channel, { detail: payload }));
      };

      component.prototype.bubble = function (channel, payload) {
        this.view.node.dispatchEvent(new CustomEvent(channel, { bubbles: true, detail: payload }));
      };

      component.prototype.trickle = function (channel, payload) {
        this.trigger(channel, payload);

        var _loop2 = function _loop2(view) {
          var tuple = broadcasts[channel].find(function (tuple) {
            return tuple[0].view.node === view.node;
          });

          if (tuple) {
            tuple[0].trigger(channel, payload);
          }
        };

        var _iteratorNormalCompletion5 = true;
        var _didIteratorError5 = false;
        var _iteratorError5 = undefined;

        try {
          for (var _iterator5 = this.view.query("*[data-ui]")[Symbol.iterator](), _step5; !(_iteratorNormalCompletion5 = (_step5 = _iterator5.next()).done); _iteratorNormalCompletion5 = true) {
            var view = _step5.value;

            _loop2(view);
          }
        } catch (err) {
          _didIteratorError5 = true;
          _iteratorError5 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion5 && _iterator5.return) {
              _iterator5.return();
            }
          } finally {
            if (_didIteratorError5) {
              throw _iteratorError5;
            }
          }
        }
      };

      return component;
    }
  }, {
    key: "components",
    get: function get$$1() {
      return components;
    }
  }, {
    key: "instances",
    get: function get$$1() {
      return instances;
    }
  }]);
  return _class;
}();

var _class$1 = function () {
  function _class() {
    var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    classCallCheck(this, _class);

    this.host = options.host || window.location.hostname;
    this.port = options.port || window.location.port;
    this.protocol = options.protocol || window.location.protocol;
    this.id = options.id || document.querySelector("meta[name='pw-connection-id']").content;
    this.endpoint = options.endpoint || document.querySelector("meta[name='pw-endpoint']").content;

    this.reconnectTimeout = this.currentReconnectTimeout = 500;
    this.reconnectDecay = 1.25;

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

  createClass(_class, [{
    key: "connect",
    value: function connect() {
      var _this = this;

      if (!this.id) {
        return;
      }

      this.connection = new WebSocket(this.websocketUrl());

      this.connection.onopen = function () {
        _this.currentReconnectTimeout = _this.reconnectTimeout;
        _this.connected = true;

        if (_this.disconnectedAt && _this.timeInMilliseconds() - _this.disconnectedAt > _this.socketBecomesStaleIn) {
          pw.broadcast("pw:socket:connected:stale");
        } else {
          pw.broadcast("pw:socket:connected");
        }

        _this.disconnectedAt = null;
      };

      this.connection.onclose = function () {
        if (_this.connected) {
          pw.broadcast("pw:socket:closed");
          _this.connected = false;
          _this.disconnectedAt = _this.timeInMilliseconds();
        }

        _this.reconnect();
      };

      this.connection.onmessage = function (event) {
        var payload = JSON.parse(event.data).payload;
        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
          for (var _iterator = (_this.subscriptions[payload.channel] || [])[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var callback = _step.value;

            callback(payload);
          }
        } catch (err) {
          _didIteratorError = true;
          _iteratorError = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion && _iterator.return) {
              _iterator.return();
            }
          } finally {
            if (_didIteratorError) {
              throw _iteratorError;
            }
          }
        }
      };
    }
  }, {
    key: "websocketUrl",
    value: function websocketUrl() {
      return this.endpoint + "?id=" + encodeURIComponent(this.id);
    }
  }, {
    key: "reconnect",
    value: function reconnect() {
      var _this2 = this;

      setTimeout(function () {
        _this2.currentReconnectTimeout *= _this2.reconnectDecay;
        _this2.connect();
      }, this.currentReconnectTimeout);
    }
  }, {
    key: "subscribe",
    value: function subscribe(channel, callback) {
      if (!this.subscriptions[channel]) {
        this.subscriptions[channel] = [];
      }

      this.subscriptions[channel].push(callback);
    }
  }, {
    key: "timeInMilliseconds",
    value: function timeInMilliseconds() {
      return new Date().getTime();
    }
  }]);
  return _class;
}();

var _class$2 = function () {
  function _class(attribute, view) {
    classCallCheck(this, _class);

    this.attribute = attribute;
    this.view = view;
  }

  createClass(_class, [{
    key: "add",
    value: function add(value) {
      this.view.node.classList.add(value);
    }
  }, {
    key: "delete",
    value: function _delete(value) {
      this.view.node.classList.remove(value);
    }
  }, {
    key: "clear",
    value: function clear() {
      this.view.node.setAttribute("class", "");
    }
  }]);
  return _class;
}();

var _class$3 = function () {
  function _class(attribute, view) {
    classCallCheck(this, _class);

    this.attribute = attribute;
    this.view = view;
  }

  createClass(_class, [{
    key: "set",
    value: function set$$1(part, value) {
      this.view.node.style[part] = value;
    }
  }, {
    key: "replace",
    value: function replace(value) {
      this.view.node.style = {};

      for (var key in value) {
        this.set(key, value[key]);
      }
    }
  }, {
    key: "delete",
    value: function _delete(part) {
      this.view.node.style[part] = null;
    }
  }, {
    key: "clear",
    value: function clear() {
      this.view.node.setAttribute("style", "");
    }
  }]);
  return _class;
}();

var _class$4 = function _class(attribute, view) {
  classCallCheck(this, _class);

  this.attribute = attribute;
  this.view = view;
};

var _class$5 = function _class(attribute, view) {
  classCallCheck(this, _class);

  this.attribute = attribute;
  this.view = view;
};

var attributeTypeSet = "set";
var attributeTypeHash = "hash";
var attributeTypeBoolean = "boolean";
var attributeTypeDefault = "string";

var attributeTypes = {
  class: attributeTypeSet,
  style: attributeTypeHash,
  selected: attributeTypeBoolean,
  checked: attributeTypeBoolean,
  disabled: attributeTypeBoolean,
  readonly: attributeTypeBoolean,
  multiple: attributeTypeBoolean
};

var attributeClasses = {};
attributeClasses[attributeTypeSet] = _class$2;
attributeClasses[attributeTypeHash] = _class$3;
attributeClasses[attributeTypeBoolean] = _class$4;
attributeClasses[attributeTypeDefault] = _class$5;

var _class$6 = function () {
  function _class(view) {
    classCallCheck(this, _class);

    this.view = view;
  }

  createClass(_class, [{
    key: "get",
    value: function get$$1(attribute) {
      var type = attributeTypes[attribute] || attributeTypeDefault;
      return new attributeClasses[type](attribute, this.view);
    }
  }, {
    key: "set",
    value: function set$$1(attribute, value) {
      var attributeType = attributeTypes[attribute];

      if (attributeType === attributeTypeHash) {
        this.get(attribute).replace(value);
      } else if (attributeType === attributeTypeSet) {
        this.view.node.setAttribute(attribute, value.join(" "));
      } else if (attributeType === attributeTypeBoolean) {
        if (value) {
          this.view.node.setAttribute(attribute, attribute);
        } else {
          this.view.node.removeAttribute(attribute);
        }
      } else {
        this.view.node.setAttribute(attribute, value);
      }
    }
  }]);
  return _class;
}();

var _class$7 = function () {
  function _class(attributes) {
    classCallCheck(this, _class);

    this.attributes = attributes;
  }

  createClass(_class, [{
    key: "set",
    value: function set$$1(part, value) {
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.attributes[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var attribute = _step.value;

          attribute.set(part, value);
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }
    }
  }, {
    key: "add",
    value: function add(value) {
      var _iteratorNormalCompletion2 = true;
      var _didIteratorError2 = false;
      var _iteratorError2 = undefined;

      try {
        for (var _iterator2 = this.attributes[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
          var attribute = _step2.value;

          attribute.add(value);
        }
      } catch (err) {
        _didIteratorError2 = true;
        _iteratorError2 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion2 && _iterator2.return) {
            _iterator2.return();
          }
        } finally {
          if (_didIteratorError2) {
            throw _iteratorError2;
          }
        }
      }
    }
  }, {
    key: "delete",
    value: function _delete(part) {
      var _iteratorNormalCompletion3 = true;
      var _didIteratorError3 = false;
      var _iteratorError3 = undefined;

      try {
        for (var _iterator3 = this.attributes[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
          var attribute = _step3.value;

          attribute.delete(part);
        }
      } catch (err) {
        _didIteratorError3 = true;
        _iteratorError3 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion3 && _iterator3.return) {
            _iterator3.return();
          }
        } finally {
          if (_didIteratorError3) {
            throw _iteratorError3;
          }
        }
      }
    }
  }, {
    key: "clear",
    value: function clear() {
      var _iteratorNormalCompletion4 = true;
      var _didIteratorError4 = false;
      var _iteratorError4 = undefined;

      try {
        for (var _iterator4 = this.attributes[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {
          var attribute = _step4.value;

          attribute.clear();
        }
      } catch (err) {
        _didIteratorError4 = true;
        _iteratorError4 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion4 && _iterator4.return) {
            _iterator4.return();
          }
        } finally {
          if (_didIteratorError4) {
            throw _iteratorError4;
          }
        }
      }
    }
  }]);
  return _class;
}();

var _class$8 = function () {
  function _class(viewSet) {
    classCallCheck(this, _class);

    this.viewSet = viewSet;
  }

  createClass(_class, [{
    key: "get",
    value: function get$$1(attribute) {
      return new _class$7(this.viewSet.views.map(function (view) {
        return view.attributes().get(attribute);
      }));
    }
  }, {
    key: "set",
    value: function set$$1(attribute, value) {
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.viewSet.views[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var view = _step.value;

          view.attributes().set(attribute, value);
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }
    }
  }]);
  return _class;
}();

var _class$9 = function () {
  function _class(views, templates) {
    classCallCheck(this, _class);

    this.views = views;
    this.templates = templates;
  }

  createClass(_class, [{
    key: "find",
    value: function find(names) {
      if (!Array.isArray(names)) {
        names = [names];
      }

      var views = [],
          templates = [];

      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.views[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var view = _step.value;

          var found = view.find(names);
          views = views.concat(found.views);

          if (!templates) {
            templates = views.templates();
          }
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      var _iteratorNormalCompletion2 = true;
      var _didIteratorError2 = false;
      var _iteratorError2 = undefined;

      try {
        for (var _iterator2 = this.templates[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
          var template = _step2.value;

          templates = templates.concat(template.templates().filter(function (view) {
            var _iteratorNormalCompletion3 = true;
            var _didIteratorError3 = false;
            var _iteratorError3 = undefined;

            try {
              for (var _iterator3 = names[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
                var name = _step3.value;

                if (view.match("binding", name)) {
                  return true;
                }
              }
            } catch (err) {
              _didIteratorError3 = true;
              _iteratorError3 = err;
            } finally {
              try {
                if (!_iteratorNormalCompletion3 && _iterator3.return) {
                  _iterator3.return();
                }
              } finally {
                if (_didIteratorError3) {
                  throw _iteratorError3;
                }
              }
            }
          }));
        }
      } catch (err) {
        _didIteratorError2 = true;
        _iteratorError2 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion2 && _iterator2.return) {
            _iterator2.return();
          }
        } finally {
          if (_didIteratorError2) {
            throw _iteratorError2;
          }
        }
      }

      return new this.constructor(views, templates);
    }
  }, {
    key: "bind",
    value: function bind(objects) {
      if (!Array.isArray(objects)) {
        objects = [objects];
      }

      var _iteratorNormalCompletion4 = true;
      var _didIteratorError4 = false;
      var _iteratorError4 = undefined;

      try {
        for (var _iterator4 = objects[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {
          var object = _step4.value;

          this.ensureViewForObject(object).bind(object);
        }
      } catch (err) {
        _didIteratorError4 = true;
        _iteratorError4 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion4 && _iterator4.return) {
            _iterator4.return();
          }
        } finally {
          if (_didIteratorError4) {
            throw _iteratorError4;
          }
        }
      }

      return this;
    }
  }, {
    key: "transform",
    value: function transform(objects, callback) {
      var _this = this;

      if (!Array.isArray(objects)) {
        objects = [objects];
      }

      if (objects.length > 0) {
        var _iteratorNormalCompletion5 = true;
        var _didIteratorError5 = false;
        var _iteratorError5 = undefined;

        try {
          for (var _iterator5 = objects[Symbol.iterator](), _step5; !(_iteratorNormalCompletion5 = (_step5 = _iterator5.next()).done); _iteratorNormalCompletion5 = true) {
            var object = _step5.value;

            this.ensureViewForObject(object).transform(object, callback);
          }
        } catch (err) {
          _didIteratorError5 = true;
          _iteratorError5 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion5 && _iterator5.return) {
              _iterator5.return();
            }
          } finally {
            if (_didIteratorError5) {
              throw _iteratorError5;
            }
          }
        }

        var _loop = function _loop(view) {
          // Remove the view if it's an empty version, since we now have data.
          if (view.match("version", "empty")) {
            _this.views.splice(_this.views.indexOf(view), 1);
            view.remove();
            return "continue";
          }

          // Remove the view if we can't find an object with its id.
          if (!objects.find(function (object) {
            return view.match("id", object["id"]);
          })) {
            _this.views.splice(_this.views.indexOf(view), 1);
            view.remove();
          }
        };

        var _iteratorNormalCompletion6 = true;
        var _didIteratorError6 = false;
        var _iteratorError6 = undefined;

        try {
          for (var _iterator6 = this.views[Symbol.iterator](), _step6; !(_iteratorNormalCompletion6 = (_step6 = _iterator6.next()).done); _iteratorNormalCompletion6 = true) {
            var view = _step6.value;

            var _ret = _loop(view);

            if (_ret === "continue") continue;
          }
        } catch (err) {
          _didIteratorError6 = true;
          _iteratorError6 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion6 && _iterator6.return) {
              _iterator6.return();
            }
          } finally {
            if (_didIteratorError6) {
              throw _iteratorError6;
            }
          }
        }

        this.order(objects);
      } else {
        var template = this.templates.find(function (template) {
          return template.version() === "empty";
        });

        if (template) {
          var createdView = template.clone();
          template.insertionPoint.parentNode.insertBefore(createdView.node, template.insertionPoint);
        }

        var _iteratorNormalCompletion7 = true;
        var _didIteratorError7 = false;
        var _iteratorError7 = undefined;

        try {
          for (var _iterator7 = this.views[Symbol.iterator](), _step7; !(_iteratorNormalCompletion7 = (_step7 = _iterator7.next()).done); _iteratorNormalCompletion7 = true) {
            var _view = _step7.value;

            _view.remove();
          }
        } catch (err) {
          _didIteratorError7 = true;
          _iteratorError7 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion7 && _iterator7.return) {
              _iterator7.return();
            }
          } finally {
            if (_didIteratorError7) {
              throw _iteratorError7;
            }
          }
        }
      }

      return this;
    }
  }, {
    key: "use",
    value: function use(version) {
      var _iteratorNormalCompletion8 = true;
      var _didIteratorError8 = false;
      var _iteratorError8 = undefined;

      try {
        for (var _iterator8 = this.views[Symbol.iterator](), _step8; !(_iteratorNormalCompletion8 = (_step8 = _iterator8.next()).done); _iteratorNormalCompletion8 = true) {
          var view = _step8.value;

          view.use(version);
        }
      } catch (err) {
        _didIteratorError8 = true;
        _iteratorError8 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion8 && _iterator8.return) {
            _iterator8.return();
          }
        } finally {
          if (_didIteratorError8) {
            throw _iteratorError8;
          }
        }
      }

      this.usableVersion = version;

      return this;
    }
  }, {
    key: "clean",
    value: function clean() {
      this.views.forEach(function (view) {
        view.clean();
      });

      return this;
    }
  }, {
    key: "attributes",
    value: function attributes() {
      return new _class$8(this);
    }
  }, {
    key: "order",
    value: function order(orderedObjects) {
      if (this.views.length == 0) {
        return;
      }

      var orderedIds = orderedObjects.map(function (object) {
        return object.id;
      });

      // Make sure the first view is correct.
      var firstMatch = this.viewWithId(orderedIds[0]);
      if (!this.views[0].match("id", orderedIds[0])) {
        firstMatch.node.parentNode.insertBefore(firstMatch.node, this.views[0].node);

        // Update `this.views` to match.
        this.views.splice(this.views.indexOf(firstMatch), 1);
        this.views.unshift(firstMatch);
      }

      // Now move the others into place.
      var currentMatch = firstMatch;
      for (var i = 0; i < orderedIds.length; i++) {
        var nextMatchId = orderedIds[i];
        var nextMatch = this.viewWithId(nextMatchId);

        if (!this.views[i].match("id", nextMatchId)) {
          nextMatch.node.parentNode.insertBefore(nextMatch.node, currentMatch.node.nextSibling);

          // Update `this.views` to match.
          this.views.splice(this.views.indexOf(nextMatch), 1);
          this.views.splice(this.views.indexOf(currentMatch), 0, nextMatch);
        }

        currentMatch = nextMatch;
      }

      return this;
    }
  }, {
    key: "append",
    value: function append(arg) {
      this.views.forEach(function (view) {
        view.append(arg);
      });

      return this;
    }
  }, {
    key: "prepend",
    value: function prepend(arg) {
      this.views.forEach(function (view) {
        view.prepend(arg);
      });

      return this;
    }
  }, {
    key: "after",
    value: function after(arg) {
      this.views.forEach(function (view) {
        view.after(arg);
      });

      return this;
    }
  }, {
    key: "before",
    value: function before(arg) {
      this.views.forEach(function (view) {
        view.before(arg);
      });

      return this;
    }
  }, {
    key: "replace",
    value: function replace(arg) {
      this.views.forEach(function (view) {
        view.replace(arg);
      });

      return this;
    }
  }, {
    key: "remove",
    value: function remove() {
      this.views.forEach(function (view) {
        view.remove();
      });

      return this;
    }
  }, {
    key: "clear",
    value: function clear() {
      this.views.forEach(function (view) {
        view.clear();
      });

      return this;
    }
  }, {
    key: "viewWithId",
    value: function viewWithId(id) {
      return this.views.find(function (view) {
        return view.match("id", id);
      });
    }
  }, {
    key: "viewForObject",
    value: function viewForObject(object) {
      return this.viewWithId(object.id);
    }
  }, {
    key: "viewHasAllBindings",
    value: function viewHasAllBindings(view, object) {
      var _loop2 = function _loop2(key) {
        if (key === "id") {
          return "continue";
        }

        if (!view.bindings().find(function (view) {
          return view.match("binding", key);
        })) {
          return {
            v: false
          };
        }
      };

      for (var key in object) {
        var _ret2 = _loop2(key);

        switch (_ret2) {
          case "continue":
            continue;

          default:
            if ((typeof _ret2 === "undefined" ? "undefined" : _typeof(_ret2)) === "object") return _ret2.v;
        }
      }

      return true;
    }
  }, {
    key: "ensureViewForObject",
    value: function ensureViewForObject(object) {
      var _this2 = this;

      var view = this.viewForObject(object);

      if (!view) {
        var template = this.templates.find(function (template) {
          return template.match("version", _this2.usableVersion || "default");
        });

        if (!template) {
          template = this.templates.filter(function (template) {
            return !template.match("version", "empty");
          })[0];
        }

        var createdView = template.clone();

        if (this.views.length == 0) {
          template.insertionPoint.parentNode.insertBefore(createdView.node, template.insertionPoint);
        } else {
          var lastView = this.views[this.views.length - 1];
          lastView.node.parentNode.insertBefore(createdView.node, lastView.node.nextSibling);
        }

        view = new pw.View(createdView.node, this.templates);
        this.views.push(view);
      } else if (!this.viewHasAllBindings(view, object)) {
        // Replace the current view with a fresh version.

        var _template = this.templates.find(function (template) {
          return template.match("version", _this2.usableVersion || "default");
        });

        if (!_template) {
          // if we don't have a default version, use the first one
          _template = this.templates[0];
        }

        var freshView = _template.clone();
        freshView.node.dataset.id = object.id;
        freshView.versions = this.templates;
        this.views[this.views.indexOf(view)] = freshView;
        view.node.parentNode.replaceChild(freshView.node, view.node);
        view = freshView;
      }

      return view;
    }
  }]);
  return _class;
}();

var _class$10 = function () {
  function _class(node) {
    var versions = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
    classCallCheck(this, _class);

    this.node = node;
    this.versions = versions;
  }

  createClass(_class, [{
    key: "id",
    value: function id() {
      return this.node.dataset.id;
    }
  }, {
    key: "binding",
    value: function binding() {
      return this.node.dataset.b;
    }
  }, {
    key: "version",
    value: function version() {
      return this.node.dataset.v || "default";
    }
  }, {
    key: "channel",
    value: function channel() {
      return this.node.dataset.c;
    }
  }, {
    key: "match",
    value: function match(property, value) {
      var propertyValue = this[property]() || "";
      value = String(value);

      if (property === "channel") {
        return propertyValue === value || propertyValue.endsWith(":" + value);
      } else {
        return propertyValue === value;
      }

      return String(value) === this[property]() || "";
    }
  }, {
    key: "attributes",
    value: function attributes() {
      return new _class$6(this);
    }
  }, {
    key: "find",
    value: function find(names, options) {
      if (!Array.isArray(names)) {
        names = [names];
      }

      names = names.slice(0);

      var currentName = names.shift();

      var templates = this.templates().filter(function (view) {
        return view.match("binding", currentName);
      });

      var found = this.bindingScopes().concat(this.bindingProps()).filter(function (view) {
        return view.node.tagName !== "FORM";
      }).map(function (view) {
        view.versions = templates;
        return view;
      }).filter(function (view) {
        return view.match("binding", currentName);
      });

      if (options && options.channel) {
        found = found.filter(function (view) {
          return view.match("channel", options.channel);
        });
      }

      if (found.length > 0 || templates.length > 0) {
        var set$$1 = new _class$9(found, templates);
        if (names.length == 0) {
          return set$$1;
        } else {
          return set$$1.find(names);
        }
      }
    }
  }, {
    key: "bind",
    value: function bind(object) {
      if (!object) {
        return;
      }

      // Insert binding props that aren't present in the view.
      this.ensureBindingPropsForObject(object);

      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = this.bindingProps()[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var view = _step.value;

          var value = object[view.binding()];

          if ((typeof value === "undefined" ? "undefined" : _typeof(value)) === "object") {
            for (var key in value) {
              var partValue = value[key];

              if (key === "content") {
                if (view.node.innerHTML !== partValue) {
                  view.node.innerHTML = partValue;
                }
              } else {
                new pw.View(view.node).attributes().set(key, partValue);
              }
            }
          } else if (typeof value === "undefined") {
            view.remove();
          } else {
            if (view.node.innerHTML !== value) {
              view.node.innerHTML = value;
            }
          }
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }

      this.node.dataset.id = object.id;

      return this;
    }
  }, {
    key: "transform",
    value: function transform(object, callback) {
      if (!object || Array.isArray(object) && object.length == 0 || Object.getOwnPropertyNames(object).length == 0) {
        this.remove();
      } else {
        // Insert binding props that aren't present in the view.
        this.ensureBindingPropsForObject(object);

        // Remove binding props that aren't in the object.
        var _iteratorNormalCompletion2 = true;
        var _didIteratorError2 = false;
        var _iteratorError2 = undefined;

        try {
          for (var _iterator2 = this.bindingProps()[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
            var view = _step2.value;

            if (!object[view.binding()]) {
              new pw.View(view.node).remove();
            }
          }
        } catch (err) {
          _didIteratorError2 = true;
          _iteratorError2 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion2 && _iterator2.return) {
              _iterator2.return();
            }
          } finally {
            if (_didIteratorError2) {
              throw _iteratorError2;
            }
          }
        }
      }

      if (callback) {
        callback(this, object);
      }

      return this;
    }
  }, {
    key: "use",
    value: function use(version) {
      if (!this.match("version", version)) {
        var templateWithVersion = this.versions.find(function (view) {
          return view.match("version", version);
        });

        if (templateWithVersion) {
          var viewWithVersion = templateWithVersion.clone();
          this.node.parentNode.replaceChild(viewWithVersion.node, this.node);
          this.node = viewWithVersion.node;
        }
      }

      return this;
    }
  }, {
    key: "clean",
    value: function clean() {
      var _this = this;

      if (this.node.parentNode) {
        // Remove templates for this view so it's gone for good.
        new pw.View(this.node.parentNode).templates().forEach(function (template) {
          if (template.match("binding", _this.binding())) {
            template.insertionPoint.parentNode.removeChild(template.insertionPoint);
          }
        });
      }

      this.remove();

      return this;
    }
  }, {
    key: "append",
    value: function append(arg) {
      this.node.appendChild(this.ensureElement(arg));

      return this;
    }
  }, {
    key: "prepend",
    value: function prepend(arg) {
      this.node.insertBefore(this.ensureElement(arg), this.node.firstChild);

      return this;
    }
  }, {
    key: "after",
    value: function after(arg) {
      this.node.parentNode.insertBefore(this.ensureElement(arg), this.node.nextSibling);

      return this;
    }
  }, {
    key: "before",
    value: function before(arg) {
      this.node.parentNode.insertBefore(this.ensureElement(arg), this.node);

      return this;
    }
  }, {
    key: "replace",
    value: function replace(arg) {
      this.node.parentNode.replaceChild(this.ensureElement(arg), this.node);

      return this;
    }
  }, {
    key: "remove",
    value: function remove() {
      if (this.node.parentNode) {
        this.node.parentNode.removeChild(this.node);
      }

      return this;
    }
  }, {
    key: "clear",
    value: function clear() {
      while (this.node.firstChild) {
        this.node.removeChild(this.node.firstChild);
      }

      return this;
    }
  }, {
    key: "setTitle",
    value: function setTitle(value) {
      var titleView = this.query("title")[0];

      if (titleView) {
        titleView.node.innerHTML = value;
      }
    }
  }, {
    key: "query",
    value: function query(selector) {
      var results = [];

      var _iteratorNormalCompletion3 = true;
      var _didIteratorError3 = false;
      var _iteratorError3 = undefined;

      try {
        for (var _iterator3 = this.node.querySelectorAll(selector)[Symbol.iterator](), _step3; !(_iteratorNormalCompletion3 = (_step3 = _iterator3.next()).done); _iteratorNormalCompletion3 = true) {
          var node = _step3.value;

          results.push(new this.constructor(node));
        }
      } catch (err) {
        _didIteratorError3 = true;
        _iteratorError3 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion3 && _iterator3.return) {
            _iterator3.return();
          }
        } finally {
          if (_didIteratorError3) {
            throw _iteratorError3;
          }
        }
      }

      return results;
    }
  }, {
    key: "bindings",
    value: function bindings() {
      return this.bindingScopes().concat(this.bindingProps());
    }
  }, {
    key: "bindingScopes",
    value: function bindingScopes() {
      var templates = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

      var bindings = [];

      this.breadthFirst(this.node, function (childNode, halt) {
        if (childNode == this.node) {
          return; // we only care about the children
        }

        if (childNode.dataset.b) {
          var childView = new pw.View(childNode);

          if (childNode.tagName === "SCRIPT" && !childNode.dataset.p || childView.bindingProps().length > 0 || new pw.View(childNode).match("version", "empty")) {
            // Don't descend into nested scopes.
            if (!bindings.find(function (binding) {
              return binding.node.contains(childNode);
            })) {
              bindings.push(childView);
            }
          }
        }
      });

      if (templates) {
        return bindings.filter(function (binding) {
          return binding.node.tagName === "SCRIPT";
        });
      } else {
        return bindings.filter(function (binding) {
          return binding.node.tagName !== "SCRIPT";
        });
      }

      return bindings;
    }
  }, {
    key: "bindingProps",
    value: function bindingProps() {
      var templates = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : false;

      var bindings = [];

      this.breadthFirst(this.node, function (childNode, halt) {
        if (childNode == this.node) {
          return; // we only care about the children
        }

        if (childNode.dataset.b) {
          if (new pw.View(childNode).bindingProps().length == 0 && !new pw.View(childNode).match("version", "empty")) {
            bindings.push(new pw.View(childNode));
          } else {
            halt(); // we're done here
          }
        }
      });

      if (templates) {
        return bindings.filter(function (binding) {
          return binding.node.tagName === "SCRIPT";
        });
      } else {
        return bindings.filter(function (binding) {
          return binding.node.tagName !== "SCRIPT";
        });
      }
    }
  }, {
    key: "templates",
    value: function templates() {
      var _this2 = this;

      var templates = this.bindingScopes(true).concat(this.bindingProps(true)).map(function (templateView) {
        // FIXME: I think it would make things more clear to create a dedicated template object
        // we could initialize with an insertion point, then have a `clone` method there rather than on view
        var view = new pw.View(_this2.ensureElement(templateView.node.innerHTML));
        view.insertionPoint = templateView.node;

        // Replace binding scopes with templates.
        var _iteratorNormalCompletion4 = true;
        var _didIteratorError4 = false;
        var _iteratorError4 = undefined;

        try {
          for (var _iterator4 = view.bindingScopes()[Symbol.iterator](), _step4; !(_iteratorNormalCompletion4 = (_step4 = _iterator4.next()).done); _iteratorNormalCompletion4 = true) {
            var binding = _step4.value;

            var template = document.createElement("script");
            template.setAttribute("type", "text/template");
            template.dataset.b = binding.binding();
            template.dataset.v = binding.version();
            template.innerHTML = binding.node.outerHTML.trim();
            binding.node.parentNode.replaceChild(template, binding.node);
          }

          // Replace binding props with templates.
        } catch (err) {
          _didIteratorError4 = true;
          _iteratorError4 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion4 && _iterator4.return) {
              _iterator4.return();
            }
          } finally {
            if (_didIteratorError4) {
              throw _iteratorError4;
            }
          }
        }

        var _iteratorNormalCompletion5 = true;
        var _didIteratorError5 = false;
        var _iteratorError5 = undefined;

        try {
          for (var _iterator5 = view.bindingProps()[Symbol.iterator](), _step5; !(_iteratorNormalCompletion5 = (_step5 = _iterator5.next()).done); _iteratorNormalCompletion5 = true) {
            var _binding = _step5.value;

            var template = document.createElement("script");
            template.setAttribute("type", "text/template");
            template.dataset.b = _binding.binding();
            template.dataset.v = _binding.version();
            // Prevents this template from being returned by `bindingScopes`.
            template.dataset.p = true;
            template.innerHTML = _binding.node.outerHTML.trim();
            _binding.node.parentNode.replaceChild(template, _binding.node);
          }
        } catch (err) {
          _didIteratorError5 = true;
          _iteratorError5 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion5 && _iterator5.return) {
              _iterator5.return();
            }
          } finally {
            if (_didIteratorError5) {
              throw _iteratorError5;
            }
          }
        }

        return view;
      });

      if (this.id()) {
        // We're looking for prop templates for a node that might have been rendered
        // on the server; try to find the prop templates that exist in the view.
        var sibling = new pw.View(this.node.parentNode).templates().find(function (template) {
          return template.match("binding", _this2.binding()) && template.match("version", _this2.version());
        });

        if (sibling) {
          templates = templates.concat(sibling.templates());
        }
      }

      return templates;
    }
  }, {
    key: "breadthFirst",
    value: function breadthFirst(node, cb) {
      var queue = [node];
      var halted = false;
      var halt = function halt() {
        halted = true;
      };
      while (!halted && queue.length > 0) {
        var subNode = queue.shift();
        if (!subNode) continue;
        if ((typeof subNode === "undefined" ? "undefined" : _typeof(subNode)) == "object" && "nodeType" in subNode && subNode.nodeType === 1 && subNode.cloneNode) {
          cb.call(this, subNode, halt);
        }

        var children = subNode.childNodes;
        if (children) {
          for (var i = 0; i < children.length; i++) {
            if (children[i].tagName) {
              queue.push(children[i]);
            }
          }
        }
      }
    }
  }, {
    key: "clone",
    value: function clone() {
      return new pw.View(this.node.cloneNode(true));
    }
  }, {
    key: "ensureElement",
    value: function ensureElement(arg) {
      if (arg instanceof Element) {
        return arg;
      } else {
        var container = document.createElement("div");
        container.innerHTML = arg.trim();
        return container.firstChild;
      }
    }
  }, {
    key: "setupEndpoint",
    value: function setupEndpoint(endpoint) {
      var endpointView = this.findEndpoint(endpoint);

      if (endpointView) {
        var endpointActionView = this.query("[data-e-a]")[0];

        if (!endpointActionView) {
          endpointActionView = endpointView;
        }

        if (endpointActionView.node.tagName === "A") {
          endpointActionView.node.setAttribute("href", endpoint.path);

          if (window.location.href === endpointActionView.node.href) {
            endpointView.node.classList.add("current");
          } else if (window.location.href.startsWith(endpointActionView.node.href)) {
            endpointView.node.classList.remove("current");
            endpointView.node.classList.add("active");
          } else {
            endpointView.node.classList.remove("current");
            endpointView.node.classList.remove("active");
          }
        } else {
          // unsupported
        }
      }
    }
  }, {
    key: "wrapEndpointForRemoval",
    value: function wrapEndpointForRemoval(endpoint) {
      var endpointView = this.findEndpoint(endpoint);

      if (endpointView) {
        var removal = document.createElement("form");
        removal.setAttribute("action", endpoint.path);
        removal.setAttribute("method", "post");
        removal.setAttribute("data-ui", "confirm");
        removal.innerHTML = '<input type="hidden" name="_method" value="delete">' + endpointView.node.outerHTML;
        endpointView.node.parentNode.replaceChild(removal, endpointView.node);
      }
    }
  }, {
    key: "findEndpoint",
    value: function findEndpoint(endpoint) {
      if (this.node.getAttribute("data-e") === endpoint.name) {
        return this;
      } else {
        return this.query("[data-e='" + endpoint.name + "']")[0];
      }
    }
  }, {
    key: "ensureBindingPropsForObject",
    value: function ensureBindingPropsForObject(object) {
      var _this3 = this;

      var _loop = function _loop(key) {
        // Skip nested data structures.
        if (object[key].constructor === Array) {
          return "continue";
        }

        if (!_this3.bindingProps().find(function (binding) {
          return binding.match("binding", key);
        })) {
          var template = _this3.templates().find(function (template) {
            return template.match("binding", key);
          });

          if (template) {
            var createdView = template.clone();
            template.insertionPoint.parentNode.insertBefore(createdView.node, template.insertionPoint);
          }
        }
      };

      for (var key in object) {
        var _ret = _loop(key);

        if (_ret === "continue") continue;
      }
    }
  }]);
  return _class;
}();



var pw$1 = Object.freeze({
	version: version,
	inits: inits,
	ready: ready,
	send: send,
	define: define,
	broadcast: broadcast,
	Component: _class,
	Socket: _class$1,
	View: _class$10
});

var _class$11 = function () {
  function _class(transformation) {
    classCallCheck(this, _class);

    this.id = transformation.id;
    this.process(transformation.calls);
  }

  createClass(_class, [{
    key: "process",
    value: function process(calls) {
      var _iteratorNormalCompletion = true;
      var _didIteratorError = false;
      var _iteratorError = undefined;

      try {
        for (var _iterator = document.querySelectorAll("*[data-t='" + this.id + "']")[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
          var node = _step.value;

          this.transform(calls, new pw.View(node));
        }
      } catch (err) {
        _didIteratorError = true;
        _iteratorError = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion && _iterator.return) {
            _iterator.return();
          }
        } finally {
          if (_didIteratorError) {
            throw _iteratorError;
          }
        }
      }
    }
  }, {
    key: "transform",
    value: function transform(calls, transformable) {
      var _this = this;

      if (!transformable) {
        return;
      }

      var _loop = function _loop(transformation) {
        var methodName = transformation[0];
        var method = transformable[methodName];

        if (method) {
          var args = transformation[1];

          if (transformation[2].length > 0) {
            var i = 0;
            args.push(function (view, object) {
              _this.transform(transformation[2][i], view);
              i++;
            });
          }

          _this.transform(transformation[3], method.apply(transformable, args));
        } else {
          console.log("unknown view method: " + methodName, transformable);
        }
      };

      var _iteratorNormalCompletion2 = true;
      var _didIteratorError2 = false;
      var _iteratorError2 = undefined;

      try {
        for (var _iterator2 = calls[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
          var transformation = _step2.value;

          _loop(transformation);
        }
      } catch (err) {
        _didIteratorError2 = true;
        _iteratorError2 = err;
      } finally {
        try {
          if (!_iteratorNormalCompletion2 && _iterator2.return) {
            _iterator2.return();
          }
        } finally {
          if (_didIteratorError2) {
            throw _iteratorError2;
          }
        }
      }
    }
  }]);
  return _class;
}();

inits.push(function () {
  window.socket = new _class$1();
  window.socket.subscribe("transformation", function (payload) {
    new _class$11(payload.message);
  });
});

inits.push(function () {
  _class.init(document.querySelector("html"));
});

ready(function () {
  inits.forEach(function (fn) {
    fn();
  });
});

return pw$1;

})));
