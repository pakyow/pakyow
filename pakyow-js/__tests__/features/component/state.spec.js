const fs = require("fs");
const path = require("path");

global.pw = require("../../../src/index");

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

describe("setting initial state on a component", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances[0].state).toEqual("initial");
  });
});

describe("setting initial state on a component from config", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo(state: state1)"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances[0].state).toEqual("state1");
  });
});

describe("setting initial state on a component from the hash", () => {
  beforeEach(() => {
    document.location.hash = btoa("foo:state1");

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances[0].state).toEqual("state1");
  });
});

describe("setting initial state on multiple components from the hash", () => {
  beforeEach(() => {
    document.location.hash = btoa("foo:state1;bar:state2");

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
        <div data-ui="bar"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  afterEach(() => {
    document.location.hash = "";
  });

  test("initializes each component", () => {
    expect(pw.Component.instances[0].state).toEqual("state1");
    expect(pw.Component.instances[1].state).toEqual("state2");
  });
});

describe("setting initial state on multiple instances of one component from the hash", () => {
  beforeEach(() => {
    document.location.hash = btoa("foo.1:state1;foo.2:state2");

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo(id: 1)"></div>
        <div data-ui="foo(id: 2)"></div>
      </body>
    `;

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes each component", () => {
    expect(pw.Component.instances[0].state).toEqual("state1");
    expect(pw.Component.instances[1].state).toEqual("state2");
  });
});

describe("calling enter transitions on initialization", () => {
  let calls = [];

  beforeEach(() => {
    calls = [];

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo(state: foo)"></div>
      </body>
    `;

    pw.define("foo", {
      constructor() {
        this.enter("foo", () => {
          calls.push("enter foo");
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
  });

  test("calls the transitions", () => {
    expect(calls[0]).toEqual("enter foo");
  });
});

describe("transitioning a component to a new state", () => {
  let calls = [];

  beforeEach(() => {
    calls = [];

    document.location.hash = btoa("foo.3:state2;baz:state3");

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
        <div data-ui="foo(id: 2)"></div>
        <div data-ui="bar"></div>
      </body>
    `;

    pw.define("foo", {
      constructor() {
        this.leave("initial", (payload) => {
          calls.push(["leave initial", payload]);
        });

        this.leave("state1", (payload) => {
          calls.push(["leave state1", payload]);
        });

        this.enter("state1", (payload) => {
          calls.push(["enter state1", payload]);
        });

        this.enter("state2", (payload) => {
          calls.push(["enter state2", payload]);
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.Component.instances[0].transition("state1", { foo: "bar" });
  });

  afterEach(() => {
    document.location.hash = "";
  });

  test("updates the state of the component", () => {
    expect(pw.Component.instances[0].state).toEqual("state1");
  });

  test("calls all leave callbacks defined for the previous transition", () => {
    expect(calls[0][0]).toEqual("leave initial");
    expect(calls[0][1]).toEqual({ foo: "bar" });
  });

  test("calls all enter callbacks defined for the transition", () => {
    expect(calls[1][0]).toEqual("enter state1");
    expect(calls[1][1]).toEqual({ foo: "bar" });
  });

  test("does not update the state of other components", () => {
    expect(pw.Component.instances[1].state).toEqual("initial");
    expect(pw.Component.instances[2].state).toEqual("initial");
  });

  test("does not call leave or enter callbacks defined for other transitions", () => {
    expect(calls.length).toEqual(2);
  });
});

describe("stickyness after transitioning a component to a new state", () => {
  let calls = [];

  describe("component is sticky", () => {
    beforeEach(() => {
      calls = [];

      document.location.hash = btoa("foo.3:state2;baz:state3");

      document.querySelector("html").innerHTML = `
        <head>
        </head>
        <body>
          <div data-ui="foo(sticky: true)"></div>
          <div data-ui="foo(id: 2)"></div>
          <div data-ui="bar"></div>
        </body>
      `;

      pw.Component.init(document.querySelector("html"));
      pw.Component.instances[0].transition("state1", { foo: "bar" });
    });

    afterEach(() => {
      document.location.hash = "";
    });

    test("updates the document hash to reflect the new state", () => {
      expect(atob(document.location.hash.substr(1))).toEqual("foo.3:state2;baz:state3;foo:state1")
    });
  });

  describe("component is not sticky", () => {
    beforeEach(() => {
      calls = [];

      document.location.hash = btoa("foo.3:state2;baz:state3");

      document.querySelector("html").innerHTML = `
        <head>
        </head>
        <body>
          <div data-ui="foo"></div>
          <div data-ui="foo(id: 2)"></div>
          <div data-ui="bar"></div>
        </body>
      `;

      pw.Component.init(document.querySelector("html"));
      pw.Component.instances[0].transition("state1", { foo: "bar" });
    });

    afterEach(() => {
      document.location.hash = "";
    });

    test("does not update the document hash", () => {
      expect(atob(document.location.hash.substr(1))).toEqual("foo.3:state2;baz:state3")
    });
  });
});

describe("enter/leave callbacks defined without an explicit state", () => {
  let calls = [];

  beforeEach(() => {
    calls = [];

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
      </body>
    `;

    pw.define("foo", {
      constructor() {
        this.leave((state, payload) => {
          calls.push([`leave ${state}`, payload]);
        });

        this.enter((state, payload) => {
          calls.push([`enter ${state}`, payload]);
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.Component.instances[0].transition("state1", { foo: "bar" });
  });

  test("calls each", () => {
    expect(calls[0][0]).toEqual("leave initial");
    expect(calls[0][1]).toEqual({ foo: "bar" });

    expect(calls[1][0]).toEqual("enter state1");
    expect(calls[1][1]).toEqual({ foo: "bar" });
  });
});
