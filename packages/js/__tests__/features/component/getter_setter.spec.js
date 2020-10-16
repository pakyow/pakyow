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

describe("defining a component with a getter and setter", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo"></div>
      </body>
    `;

    pw.define("foo", {
      set foo(value) {
        this.__foo = "foo" + value;
      },

      get foo() {
        return this.__foo;
      }
    });

    pw.Component.init(document.querySelector("html"));
  });

  test("defines the getter and setter", () => {
    pw.Component.instances[0].foo = "bar";
    expect(pw.Component.instances[0].foo).toEqual("foobar");
  });
});
