require("../support/helpers/setup.js");
require("../support/helpers/components.js");

describe("debugging a component", () => {
  let init = () => {
    pw.Component.init(document.querySelector("html"));
  }

  let spy;

  beforeEach(() => {
    spy = jest.spyOn(console, "debug").mockImplementation(() => {});

    document.querySelector("html").innerHTML = `
      <head>
      </head>
      <body>
        <div data-ui="foo(debug: true)"></div>
        <div data-ui="bar(debug: true)"></div>
      </body>
    `;
  });

  test("logs initialization", () => {
    init();
    expect(spy.mock.calls).toEqual([
      ["[component] foo initializing"],
      ["[component] foo initialized"],
      ["[component] bar initializing"],
      ["[component] bar initialized"]
    ]);
  });

  test("logs listen", () => {
    init();
    spy.mockClear();
    pw.Component.instances[0].listen("foo", () => {});

    expect(spy.mock.calls).toEqual([
      ["[component] foo listening for events on `foo'"]
    ]);
  });

  test("logs ignore", () => {
    init();
    spy.mockClear();
    pw.Component.instances[0].ignore("foo");

    expect(spy.mock.calls).toEqual([
      ["[component] foo ignoring events on `foo'"]
    ]);
  });

  test("logs trigger", () => {
    init();
    pw.Component.instances[0].listen("bar", () => {});
    spy.mockClear();
    pw.broadcast("bar", { bar: "baz" });

    expect(spy.mock.calls).toEqual([
      ["[component] foo triggering `bar': {\"bar\":\"baz\"}"]
    ]);
  });

  test("logs trigger", () => {
    init();
    spy.mockClear();
    pw.Component.instances[0].bubble("baz", { bar: "baz" });

    expect(spy.mock.calls).toEqual([
      ["[component] foo bubbling `baz': {\"bar\":\"baz\"}"]
    ]);
  });
});
