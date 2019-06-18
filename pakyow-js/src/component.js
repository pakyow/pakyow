var broadcasts = {};
var components = {};
var instances = [];
var observer;

export default class {
  static get components() {
    return components;
  }

  static get instances() {
    return instances;
  }

  static register(name, component) {
    components[name] = component;
  }

  static init(node) {
    if (!observer) {
      observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.addedNodes) {
            for (let node of mutation.addedNodes) {
              this.componentsForView(new pw.View(node)).forEach((view) => {
                this.componentFromView(view);
              });
            }
          }

          if (mutation.removedNodes) {
            for (let node of mutation.removedNodes) {
              this.componentsForView(new pw.View(node)).forEach((view) => {
                let component = instances.find((component) => {
                  return component.view.node === view.node;
                });

                if (component) {
                  component.channels.slice(0).forEach((channel) => {
                    component.ignore(channel);
                  });

                  instances.splice(instances.indexOf(component), 1);

                  component.disappear();
                }
              });
            }
          }
        });
      });

      observer.observe(document.documentElement, {
        attributes: true,
        childList: true,
        subtree: true
      });
    }

    this.componentsForView(new pw.View(node)).forEach((view) => {
      this.componentFromView(view);
    });
  }

  static componentsForView(view) {
    let components = [];

    if (view.node.tagName) {
      if (view.node.dataset.ui) {
        components.push(view);
      }

      components = components.concat(view.query("[data-ui]"))
    }

    return components;
  }

  static componentFromView(view) {
    if (!instances.find((component) => { return component.view.node === view.node })) {
      var uiComponents = this.parseUI(view.node.dataset.ui);

      for (let uiComponent of uiComponents) {
        let object = components[uiComponent.name] || this.create();
        let instance = new object(view, uiComponent.config);
        instances.push(instance);
        instance.appear();
      }
    }
  }

  static broadcast(channel, payload) {
    for (let tuple of (broadcasts[channel] || [])) {
      tuple[0].trigger(channel, payload);
    }
  }

  static parseUI(uiString) {
    return uiString.split(";").reduce((config, ui) => {
      let splitUi = ui.split("(");
      let uiName = splitUi[0].trim();
      let uiConfig = {};

      if (splitUi[1]) {
        let configString = splitUi[1].trim();
        configString = configString.substring(0, configString.length - 1);
        uiConfig = this.parseConfig(configString);
      }

      config.push({ name: uiName, config: uiConfig });
      return config;
    }, []);
  }

  static parseConfig(configString) {
    if (typeof configString === "undefined") {
      return {};
    }

    return configString.split(",").reduce((config, option) => {
      let splitOption = option.trim().split(":");

      let key = splitOption.shift().trim();
      let value;

      if (splitOption.length === 0) {
        value = true;
      } else {
        value = splitOption.join(":").trim();
      }

      config[key] = value;
      return config;
    }, {});
  }

  static clearObserver() {
    if (observer) {
      observer.disconnect();
      observer = null;
    }
  }

  static create() {
    var component = function(view, config = {}) {
      this.view = view;
      this.node = view.node;
      this.config = config;
      this.channels = [];
    };

    component.prototype.appear = function () {
      // intentionally empty
    };

    component.prototype.disappear = function () {
      // intentionally empty
    };

    component.prototype.listen = function (channel, callback) {
      this.view.node.addEventListener(channel, (evt) => {
        callback.call(this, evt.detail);
      });

      if (!broadcasts[channel]) {
        broadcasts[channel] = [];
      }

      broadcasts[channel].push([this, callback]);
      this.channels.push(channel);
    };

    component.prototype.ignore = function (channel) {
      broadcasts[channel].filter((tuple) => {
        return tuple[0].view.node === this.view.node;
      }).forEach((tuple) => {
        this.view.node.removeEventListener(channel, tuple[1]);
        broadcasts[channel].splice(broadcasts[channel].indexOf(tuple), 1);
      });

      this.channels.splice(this.channels.indexOf(channel), 1);
    };

    component.prototype.trigger = function (channel, payload) {
      this.view.node.dispatchEvent(
        new CustomEvent(channel, { detail: payload })
      );
    };

    component.prototype.bubble = function (channel, payload) {
      this.view.node.dispatchEvent(
        new CustomEvent(channel, { bubbles: true, detail: payload })
      );
    };

    component.prototype.trickle = function (channel, payload) {
      this.trigger(channel, payload);

      for (let view of this.view.query("*[data-ui]")) {
        let tuple = broadcasts[channel].find((tuple) => {
          return tuple[0].view.node === view.node;
        });

        if (tuple) {
          tuple[0].trigger(channel, payload);
        }
      }
    }

    return component;
  }
}
