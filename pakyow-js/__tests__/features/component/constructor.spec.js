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

describe("defining a component with a constructor", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
      </body>
    `;

    pw.define("foo", {
      constructor() {
        this.foo = "bar";
      }
    });

    pw.Component.init(document.querySelector("html"));
  });

  test("it is called", () => {
    expect(pw.Component.instances[0].foo).toEqual("bar");
  });

  test("it still calls the default constructor", () => {
    expect(pw.Component.instances[0].config).toEqual({ name: "foo" });
  });
});
