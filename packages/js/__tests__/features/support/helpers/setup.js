require("mutationobserver-shim");
global.MutationObserver = window.MutationObserver;
global.pw = require("../../../../src/index");

Object.defineProperty(window, 'location', {
  writable: true,
  value: {
    href: "http://pakyow.local/",
    pathname: "/",

    assign: jest.fn(),
    reload: jest.fn()
  }
});
