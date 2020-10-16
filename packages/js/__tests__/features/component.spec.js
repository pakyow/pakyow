require("./support/helpers/setup.js");
require("./support/helpers/components.js");

import {default as sleep} from "./support/helpers/sleep.js";

describe("initializing components in a node", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
        <div data-ui="bar(key1: val1)"></div>
        <div data-ui="baz(val1, key2: val2)"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances.length).toBe(3);
  });

  test("initializes each component with a view", () => {
    expect(pw.Component.instances[0].view.node.dataset.ui).toEqual("foo")
    expect(pw.Component.instances[1].view.node.dataset.ui).toEqual("bar(key1: val1)")
    expect(pw.Component.instances[2].view.node.dataset.ui).toEqual("baz(val1, key2: val2)")
  });

  test("initializes each component with a node", () => {
    expect(pw.Component.instances[0].node.dataset.ui).toEqual("foo")
    expect(pw.Component.instances[1].node.dataset.ui).toEqual("bar(key1: val1)")
    expect(pw.Component.instances[2].node.dataset.ui).toEqual("baz(val1, key2: val2)")
  });

  test("initializes each component with its config", () => {
    expect(pw.Component.instances[0].config).toEqual({ name: "foo" })
    expect(pw.Component.instances[1].config).toEqual({ name: "bar", key1: "val1" })
    expect(pw.Component.instances[2].config).toEqual({ name: "baz", "val1": true, key2: "val2" })
  });

  test("does not reinitialize a component that exists", () => {
    pw.Component.init(document.querySelector("html"));
    expect(pw.Component.instances.length).toBe(3);
  });
});

describe("parsing component config with values that contain colons", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo(key1: val:1, key2: val2)"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("parses correctly", () => {
    expect(pw.Component.instances[0].config).toEqual({ name: "foo", key1: "val:1", key2: "val2" })
  });
});

describe("initializing multiple components for a node", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo; bar(key1: val1); baz(val1, key2: val2)"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances.length).toBe(3);
  });

  test("initializes each component with a view", () => {
    expect(pw.Component.instances[0].view.node.dataset.ui).toEqual("foo; bar(key1: val1); baz(val1, key2: val2)")
    expect(pw.Component.instances[1].view.node.dataset.ui).toEqual("foo; bar(key1: val1); baz(val1, key2: val2)")
    expect(pw.Component.instances[2].view.node.dataset.ui).toEqual("foo; bar(key1: val1); baz(val1, key2: val2)")
  });

  test("initializes each component with a node", () => {
    expect(pw.Component.instances[0].node.dataset.ui).toEqual("foo; bar(key1: val1); baz(val1, key2: val2)")
    expect(pw.Component.instances[1].node.dataset.ui).toEqual("foo; bar(key1: val1); baz(val1, key2: val2)")
    expect(pw.Component.instances[2].node.dataset.ui).toEqual("foo; bar(key1: val1); baz(val1, key2: val2)")
  });

  test("initializes each component with its config", () => {
    expect(pw.Component.instances[0].config).toEqual({ name: "foo" })
    expect(pw.Component.instances[1].config).toEqual({ name: "bar", key1: "val1" })
    expect(pw.Component.instances[2].config).toEqual({ name: "baz", "val1": true, key2: "val2" })
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

  test("creates component instances for each added node", async () => {
    expect(pw.Component.instances.length).toBe(1);
    let component = document.createElement("div");
    component.innerHTML = `<div data-ui="bar"></div>`;
    document.querySelector("body").appendChild(component.firstChild);
    await sleep(50);
    expect(pw.Component.instances.length).toBe(2);
  });

  test("it calls appear for each matching component", async () => {
    var appeared = [];

    pw.define("bar", {
      appear() {
        appeared.push(this);
      }
    });

    let component = document.createElement("div");
    component.innerHTML = `<div data-ui="bar"></div>`;
    document.querySelector("body").appendChild(component.firstChild);
    await sleep(50);

    expect(appeared.length).toBe(1);
  });
});

describe("adding nested component nodes to the dom", () => {
  beforeEach(() => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("creates component instances for each added node", async () => {
    expect(pw.Component.instances.length).toBe(1);
    let component = document.createElement("div");
    component.innerHTML = `<main><div data-ui="bar"></div></main>`;
    document.querySelector("body").appendChild(component.firstChild);
    await sleep(50);
    expect(pw.Component.instances.length).toBe(2);
  });
});

describe("removing component nodes from the dom", () => {
  test("removes the component instance tied to the removed node", async () => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
      <div data-ui="bar"></div>
    `;

    pw.Component.init(document.querySelector("html"));

    expect(pw.Component.instances.length).toBe(2);
    new pw.View(document.querySelector("*[data-ui='foo']")).remove();
    await sleep(50);
    expect(pw.Component.instances.length).toBe(1);
    new pw.View(document.querySelector("*[data-ui='bar']")).remove();
    await sleep(50);
    expect(pw.Component.instances.length).toBe(0);
  });

  test("it calls disappear for each matching component", async () => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>
    `;

    var disappeared = [];

    pw.define("foo", {
      disappear() {
        disappeared.push(this);
      }
    });

    pw.Component.init(document.querySelector("html"));
    await sleep(50);
    new pw.View(document.querySelector("*[data-ui='foo']")).remove();
    await sleep(50);

    expect(disappeared.length).toEqual(1);
  });
});

describe("removing nested component nodes from the dom", () => {
  test("removes the component instance tied to the removed node", async () => {
    document.querySelector("body").innerHTML = `
      <div data-ui="foo"></div>

      <main>
        <div data-ui="bar"></div>
      </main>
    `;

    pw.Component.init(document.querySelector("html"));

    expect(pw.Component.instances.length).toBe(2);
    new pw.View(document.querySelector("*[data-ui='foo']")).remove();
    await sleep(50);
    expect(pw.Component.instances.length).toBe(1);
    new pw.View(document.querySelector("main")).remove();
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

  test("it calls appear for each matching component", () => {
    pw.define("foo", {
      appear() {
        this.appeared = true;
      }
    });

    pw.Component.init(document.querySelector("html"));

    expect(pw.Component.instances[0].appeared).toEqual(true);
    expect(pw.Component.instances[2].appeared).toEqual(true);
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
      appear() {
        this.listen("test:channel1", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("bar", {
      appear() {
        this.listen("test:channel2", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("baz", {
      appear() {
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
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });

        this.listen("test:channel", (payload) => {
          this.called_again = payload;
        });
      }
    });

    pw.define("bar", {
      appear() {
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
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar", {
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar:baz", {
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("bar", {
      appear() {
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
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar", {
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("foo:bar:baz", {
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });
      }
    });

    pw.define("bar", {
      appear() {
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
      appear() {
        this.listen("test:channel", (payload) => {
          this.called = payload;
        });

        this.listen("test:channel", (payload) => {
          this.called_again = payload;
        });
      }
    });

    pw.define("bar", {
      appear() {
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
