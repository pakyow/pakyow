const fs = require("fs");
const path = require("path");

global.pw = require("../../src/index");

require('mutationobserver-shim');
global.MutationObserver = window.MutationObserver;

function sleep(ms){
  return new Promise(resolve=>{
    setTimeout(resolve, ms)
  });
}

afterEach(() => {
  while(pw.Component.instances.length > 0) {
    pw.Component.instances.pop();
  }

  pw.Component.clearObserver();
});

describe("initializing components in a node", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
        <div data-ui="bar" data-config="key1: val1"></div>
        <div data-ui="baz" data-config="key1: val1; key2: val2"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances.length).toBe(3);
  });

  test("initializes each component with a view", () => {
    expect(pw.Component.instances[0].view.node.dataset.ui).toEqual("foo")
    expect(pw.Component.instances[1].view.node.dataset.ui).toEqual("bar")
    expect(pw.Component.instances[2].view.node.dataset.ui).toEqual("baz")
  });

  test("initializes each component with its config", () => {
    expect(pw.Component.instances[0].config).toEqual({})
    expect(pw.Component.instances[1].config).toEqual({ key1: "val1" })
    expect(pw.Component.instances[2].config).toEqual({ key1: "val1", key2: "val2" })
  });

  test("does not reinitialize a component that exists", () => {
    pw.Component.init(document.querySelector("html"));
    expect(pw.Component.instances.length).toBe(3);
  });
});

describe("adding component nodes to the dom", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("removes the component instance tied to the removed node", async () => {
    expect(pw.Component.instances.length).toBe(1);
    let component = document.createElement("div");
    component.innerHTML = `<div data-ui="bar"></div>`;
    document.querySelector("body").appendChild(component.firstChild);
    await sleep(50);
    expect(pw.Component.instances.length).toBe(2);
  });
});

describe("removing component nodes from the dom", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
      <div data-ui="bar"></div>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("removes the component instance tied to the removed node", async () => {
    expect(pw.Component.instances.length).toBe(2);
    new pw.View(document.querySelector("*[data-ui='foo']")).remove();
    await sleep(50);
    expect(pw.Component.instances.length).toBe(1);
    new pw.View(document.querySelector("*[data-ui='bar']")).remove();
    await sleep(50);
    expect(pw.Component.instances.length).toBe(0);
  });
});

describe("registering a component", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
      <div data-ui="bar"></div>
      <div data-ui="foo"></div>
    `;
  });

  test("it is initialized for the matching component", () => {
    pw.define("foo", {
      foo() {
        return "foo";
      }
    });

    pw.Component.init(document.querySelector("html"));

    expect(pw.Component.instances[0].foo()).toEqual("foo");
    expect(pw.Component.instances[2].foo()).toEqual("foo");
  });

  test("it calls ready for each matching component", () => {
    pw.define("foo", {
      ready() {
        this.ready = true;
      }
    });

    pw.Component.init(document.querySelector("html"));

    expect(pw.Component.instances[0].ready).toEqual(true);
    expect(pw.Component.instances[2].ready).toEqual(true);
  });
});

describe("broadcasting an event", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
      <div data-ui="bar"></div>
      <div data-ui="baz"></div>
    `;
  });

  test("reaches each listening component", () => {
    pw.define("foo", {
      ready() {
        this.listen("test:channel1", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("bar", {
      ready() {
        this.listen("test:channel2", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("baz", {
      ready() {
        this.listen("test:channel1", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.broadcast("test:channel1", "foo");

    expect(pw.Component.instances[0].called).toBe("foo");
    expect(pw.Component.instances[1].called).toBe(undefined);
    expect(pw.Component.instances[2].called).toBe("foo");
  });
});

describe("triggering an event", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
      <div data-ui="bar"></div>
    `;
  });

  test("calls each handler", () => {
    pw.define("foo", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });

        this.listen("test:channel", (payload) => {
          this.called_again = payload;
        });
      }
    });

    pw.define("bar", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.Component.instances[0].trigger("test:channel", "foo");

    expect(pw.Component.instances[0].called).toBe("foo");
    expect(pw.Component.instances[0].called_again).toBe("foo");
    expect(pw.Component.instances[1].called).toBe(undefined);
  });
});

describe("bubbling an event", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo">
        <div data-ui="foo:bar">
          <div data-ui="foo:bar:baz"></div>
        </div>
      </div>
      <div data-ui="bar"></div>
    `;
  });

  test("bubbles up to each handler", () => {
    pw.define("foo", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar:baz", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("bar", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.Component.instances[2].bubble("test:channel", "foo");

    expect(pw.Component.instances[0].called).toBe("foo");
    expect(pw.Component.instances[1].called).toBe("foo");
    expect(pw.Component.instances[2].called).toBe("foo");
    expect(pw.Component.instances[3].called).toBe(undefined);
  });
});

describe("trickling an event", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo">
        <div data-ui="foo:bar">
          <div data-ui="foo:bar:baz"></div>
        </div>
      </div>
      <div data-ui="bar"></div>
    `;
  });

  test("trickles down to each handler", () => {
    pw.define("foo", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar:baz", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("bar", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.Component.instances[0].trickle("test:channel", "foo");

    expect(pw.Component.instances[0].called).toBe("foo");
    expect(pw.Component.instances[1].called).toBe("foo");
    expect(pw.Component.instances[2].called).toBe("foo");
    expect(pw.Component.instances[3].called).toBe(undefined);
  });
});

describe("ignoring broadcasts", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
      <div data-ui="bar"></div>
    `;
  });

  test("reaches each listening component", () => {
    pw.define("foo", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });

        this.listen("test:channel", (payload) => {
          this.called_again = payload;
        });
      }
    });

    pw.define("bar", {
      ready() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.Component.init(document.querySelector("html"));

    pw.broadcast("test:channel", "foo");
    expect(pw.Component.instances[0].called).toBe("foo");
    expect(pw.Component.instances[0].called_again).toBe("foo");
    expect(pw.Component.instances[1].called).toBe("foo");

    pw.Component.instances[0].ignore("test:channel");

    pw.broadcast("test:channel", "bar");
    expect(pw.Component.instances[0].called).toBe("foo");
    expect(pw.Component.instances[0].called_again).toBe("foo");
    expect(pw.Component.instances[1].called).toBe("bar");
  });
});
