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

describe("emitting events when a component transitions between states", () => {
  let siblingCalls = [];
  let childrenCalls = [];

  beforeEach(() => {
    siblingCalls = [];
    childrenCalls = [];

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="sibling; foo">
          <div data-ui="child"></div>
        </div>
      </body>
    `;

    pw.define("sibling", {
      constructor() {
        this.listen("foo:leave:initial", (payload) => {
          siblingCalls.push(["foo:leave:initial", payload]);
        });

        this.listen("foo:enter:state1", (payload) => {
          siblingCalls.push(["foo:enter:state1", payload]);
        });
      }
    });

    pw.define("child", {
      constructor() {
        this.listen("foo:leave:initial", (payload) => {
          childrenCalls.push(["foo:leave:initial", payload]);
        });

        this.listen("foo:enter:state1", (payload) => {
          childrenCalls.push(["foo:enter:state1", payload]);
        });
      }
    });

    pw.Component.init(document.querySelector("html"));
    pw.Component.instances[1].transition("state1", { foo: "bar" });
  });

  test("trickles events to siblings and children", () => {
    expect(siblingCalls[0][0]).toEqual('foo:leave:initial');
    expect(siblingCalls[0][1]).toEqual({ foo: "bar" });
    expect(siblingCalls[1][0]).toEqual('foo:enter:state1');
    expect(siblingCalls[1][1]).toEqual({ foo: "bar" });

    expect(childrenCalls[0][0]).toEqual('foo:leave:initial');
    expect(childrenCalls[0][1]).toEqual({ foo: "bar" });
    expect(childrenCalls[1][0]).toEqual('foo:enter:state1');
    expect(childrenCalls[1][1]).toEqual({ foo: "bar" });
  });
});
