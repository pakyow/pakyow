var broadcasts = {};
var components = {};
var instances = [];
var states = {};
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
    let serializedState = window.localStorage.getItem(
      `pw:component-state:${window.location.pathname}`
     );

    if (serializedState) {
      states = this.parseState(serializedState);
    } else {
      states = {};
    }

    if (!instances.find((component) => { return component.view.node === view.node })) {
      var uiComponents = this.parseUI(view.node.dataset.ui);

      for (let uiComponent of uiComponents) {
        try {
          if (uiComponent.config.debug) {
            console.debug(`[component] \`${uiComponent.name}': initializing`);
          }

          let object = components[uiComponent.name] || this.create();
          let instance = new object(view, Object.assign({ name: uiComponent.name }, uiComponent.config));
          instances.push(instance);

          let matcher = uiComponent.name;

          if (instance.config.id) {
            matcher = `${matcher}.${instance.config.id}`;
          }

          if (states[matcher]) {
            instance.state = states[matcher];
          } else {
            instance.state = instance.config.state || "initial";
          }

          if (instance.state !== "initial") {
            instance.transition(instance.state);
          }

          instance.appear();

          if (instance.config.debug) {
            console.debug(`[component] \`${uiComponent.name}': initialized`);
          }
        } catch (error) {
          console.error(`failed to initialize component \`${uiComponent.name}': ${error}`);
        }
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

  static parseState(stateString) {
    if (typeof stateString === "undefined" || stateString === "") {
      return {};
    }

    return stateString.trim().split(";").reduce((state, componentState) => {
      let componentStateArr = componentState.trim().split(":");
      state[componentStateArr[0].trim()] = componentStateArr[1].trim();
      return state;
    }, {});
  }

  static clearObserver() {
    if (observer) {
      observer.disconnect();
      observer = null;
    }
  }

  static create() {
    var defaultConstructor = function(view, config = {}) {
      this.view = view;
      this.node = view.node;
      this.config = config;
      this.channels = [];
      this.transitions = { enter: [], leave: [] };

      if (this.constructor && this.constructor !== defaultConstructor) {
        this.constructor();
      }
    };

    var component = defaultConstructor;

    component.prototype.appear = function () {
      // intentionally empty
    };

    component.prototype.disappear = function () {
      // intentionally empty
    };

    component.prototype.listen = function (channel, callback) {
      if (this.config.debug) {
        console.debug(`[component] ${this.config.name} listening for events on \`${channel}'`);
      }

      this.node.addEventListener(channel, (evt) => {
        callback.call(this, evt.detail);
      });

      if (!broadcasts[channel]) {
        broadcasts[channel] = [];
      }

      broadcasts[channel].push([this, callback]);
      this.channels.push(channel);
    };

    component.prototype.ignore = function (channel) {
      if (this.config.debug) {
        console.debug(`[component] ${this.config.name} ignoring events on \`${channel}'`);
      }

      broadcasts[channel].filter((tuple) => {
        return tuple[0].view.node === this.view.node;
      }).forEach((tuple) => {
        this.view.node.removeEventListener(channel, tuple[1]);
        broadcasts[channel].splice(broadcasts[channel].indexOf(tuple), 1);
      });

      this.channels.splice(this.channels.indexOf(channel), 1);
    };

    component.prototype.trigger = function (channel, payload) {
      if (this.config.debug) {
        console.debug(`[component] ${this.config.name} triggering \`${channel}': ${JSON.stringify(payload)}`);
      }

      this.view.node.dispatchEvent(
        new CustomEvent(channel, { detail: payload })
      );
    };

    component.prototype.bubble = function (channel, payload) {
      if (this.config.debug) {
        console.debug(`[component] ${this.config.name} bubbling \`${channel}': ${JSON.stringify(payload)}`);
      }

      this.view.node.dispatchEvent(
        new CustomEvent(channel, { bubbles: true, detail: payload })
      );
    };

    component.prototype.trickle = function (channel, payload) {
      this.trigger(channel, payload);

      if (broadcasts[channel]) {
        for (let view of this.view.query("*[data-ui]")) {
          let tuple = broadcasts[channel].find((tuple) => {
            return tuple[0].view.node === view.node;
          });

          if (tuple) {
            tuple[0].trigger(channel, payload);
          }
        }
      }
    };

    component.prototype.transition = function (state, payload) {
      let enterTransitions = this.transitions.enter.filter((transition) => {
        return transition.state === state;
      });

      let leaveTransitions = this.transitions.leave.filter((transition) => {
        return transition.state === this.state;
      });

      let generalEnterTransitions = this.transitions.enter.filter((transition) => {
        return typeof transition.state === "undefined";
      });

      let generalLeaveTransitions = this.transitions.leave.filter((transition) => {
        return typeof transition.state === "undefined";
      });

      for (let transition of leaveTransitions) {
        transition.callback(payload);
      }

      for (let transition of generalLeaveTransitions) {
        transition.callback(this.state, payload);
      }

      this.trickle(`${this.config.name}:leave:${this.state}`, payload);

      this.node.classList.remove(`ui-state-${this.state}`);

      this.state = state;

      this.node.classList.add(`ui-state-${this.state}`);

      let referenceName = this.config.name;
      if (this.config.id) {
        referenceName = `${referenceName}.${this.config.id}`;
      }

      let update = {};
      update[referenceName] = this.state;
      Object.assign(states, update);

      let values = [];
      for (let key in states) {
        values.push(`${key}:${states[key]}`);
      }

      if (this.config.sticky) {
        window.localStorage.setItem(`pw:component-state:${window.location.pathname}`, values.join(";"))
      }

      for (let transition of enterTransitions) {
        transition.callback(payload);
      }

      for (let transition of generalEnterTransitions) {
        transition.callback(this.state, payload);
      }

      this.trickle(`${this.config.name}:enter:${this.state}`, payload);
    };

    component.prototype.enter = function (state, callback) {
      let object;

      if (typeof callback === "undefined") {
        object = {
          callback: state
        }
      } else {
        object = {
          state: state, callback: callback
        }
      }

      this.transitions.enter.push(object);
    };

    component.prototype.leave = function (state, callback) {
      let object;

      if (typeof callback === "undefined") {
        object = {
          callback: state
        }
      } else {
        object = {
          state: state, callback: callback
        }
      }

      this.transitions.leave.push(object);
    };

    return component;
  }
}
