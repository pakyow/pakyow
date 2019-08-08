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

let originalConsole = console;

beforeEach(() => {
  console.error = jest.fn();
});

afterEach(() => {
  while(pw.Component.instances.length > 0) {
    pw.Component.instances.pop();
  }

  pw.Component.clearObserver();

  console.error = originalConsole.error;
});

describe("component errors on initialization", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo(fail: true); bar"></div>
        <div data-ui="foo"></div>
        <div data-ui="bar"></div>
      </body>
    `;

    pw.define("foo", {
      constructor() {
        if (this.config.fail) {
          throw "failed";
        }
      }
    });

    pw.define("bar", {
    });

    pw.Component.init(document.querySelector("html"));
  });

  test("initializes the correct number of components", () => {
    expect(pw.Component.instances.length).toEqual(3);
  });
});
