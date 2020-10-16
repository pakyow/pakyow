function mockFunctions() {
  const original = jest.requireActual('../../../src/index');
  return {
    ...original,
    send: jest.fn().mockImplementation((url, options) => {
      if (url.includes("succeeded")) {
        options.success();
      }

      if (url.includes("errored")) {
        options.error();
      }
    })
  }
}

jest.mock('../../../src/index', () => mockFunctions());

require("../support/helpers/setup.js");
require("../support/helpers/components.js");

require("../../../src/components/devtools.js");

describe("devtools", () => {
  describe("setting the initial view path mapping", () => {
    describe("in the development environment", () => {
      beforeEach(() => {
        document.querySelector("html").innerHTML = `
          <head></head>

          <body>
            <div data-ui="devtools(environment: development, viewPath: /foo)"></div>
          </body>
        `;
      });

      test("sets the mapping for the view path to the location href", () => {
        let spy = jest.spyOn(window.localStorage, "setItem");
        pw.Component.init(document.querySelector("html"));
        expect(spy).toHaveBeenCalledWith(
          "pw:devtools-view-path-mapping:/foo",
          "http://pakyow.local/"
        );
      });
    });

    describe("in prototype the mode environment", () => {
      beforeEach(() => {
        document.querySelector("html").innerHTML = `
          <head></head>

          <body>
            <div data-ui="devtools(environment: prototype, viewPath: /foo)"></div>
          </body>
        `;
      });

      test("does not set the mapping for the view path", () => {
        let spy = jest.spyOn(window.localStorage, "setItem");
        pw.Component.init(document.querySelector("html"));
        expect(spy).not.toHaveBeenCalled();
      });
    });
  });

  describe("toggling modes", () => {
    describe("in the development environment", () => {
      beforeEach(() => {
        document.querySelector("html").innerHTML = `
          <head></head>

          <body>
            <div data-ui="devtools(environment: development, viewPath: /foo)"></div>
          </body>
        `;

        pw.Component.init(document.querySelector("html"));
      });

      test("sends the restart request for prototype", () => {
        pw.broadcast("devtools:toggle-environment");
        expect(pw.send).toHaveBeenCalledWith(
          "/pw-restart?environment=prototype",
          expect.objectContaining({
            error: expect.any(Function),
            success: expect.any(Function)
          })
        );
      });
    });

    describe("in the prototype environment", () => {
      beforeEach(() => {
        document.querySelector("html").innerHTML = `
          <head></head>

          <body>
            <div data-ui="devtools(environment: prototype, viewPath: /bar)"></div>
          </body>
        `;

        pw.Component.init(document.querySelector("html"));
      });

      test("sends the restart request for development", () => {
        pw.broadcast("devtools:toggle-environment");
        expect(pw.send).toHaveBeenCalledWith(
          "/pw-restart?environment=development",
          expect.objectContaining({
            error: expect.any(Function),
            success: expect.any(Function)
          })
        );
      });
    });

    describe("request is successful", () => {
      beforeEach(() => {
        document.querySelector("html").innerHTML = `
          <head></head>

          <body>
            <div data-ui="devtools(environment: development, viewPath: /foo)"></div>
          </body>
        `;

        pw.Component.init(document.querySelector("html"));
      });

      test("transitions to restarting", () => {
        jest.spyOn(pw.Component.instances[0], "switchToEnvironment").mockImplementation(() => { return "succeeded" });
        let spy = jest.spyOn(pw.Component.instances[0], "transition");
        pw.broadcast("devtools:toggle-environment");
        expect(spy).toHaveBeenCalledWith("restarting");
      });
    });

    describe("request is unsuccessful", () => {
      let consoleSpy;

      beforeEach(() => {
        document.querySelector("html").innerHTML = `
          <head></head>

          <body>
            <div data-ui="devtools(environment: development, viewPath: /foo)"></div>
          </body>
        `;

        pw.Component.init(document.querySelector("html"));

        consoleSpy = jest.spyOn(console, "error").mockImplementation(() => {});
      });

      test("does not transition", () => {
        jest.spyOn(pw.Component.instances[0], "switchToEnvironment").mockImplementation(() => { return "errored" });
        let spy = jest.spyOn(pw.Component.instances[0], "transition");
        pw.broadcast("devtools:toggle-environment");
        expect(spy).not.toHaveBeenCalled();
      });

      test("logs an error", () => {
        jest.spyOn(pw.Component.instances[0], "switchToEnvironment").mockImplementation(() => { return "errored" });
        let spy = jest.spyOn(pw.Component.instances[0], "transition");
        pw.broadcast("devtools:toggle-environment");
        expect(consoleSpy).toHaveBeenCalledWith("[devtools] could not restart");
      });
    });
  });

  describe("socket connects", () => {
    describe("devtools is in a restarting state", () => {
      describe("in the development environment", () => {
        beforeEach(() => {
          document.querySelector("html").innerHTML = `
            <head></head>

            <body>
              <div data-ui="devtools(environment: development, viewPath: /foo)"></div>
            </body>
          `;

          pw.Component.init(document.querySelector("html"));
          pw.Component.instances[0].transition("restarting");
        });

        test("sets the document location to the view path", () => {
          window.location.assign = jest.fn();
          pw.broadcast("pw:socket:connected", { config: {} });
          expect(window.location.assign).toHaveBeenCalledWith("/foo");
        });
      });

      describe("in the prototype environment", () => {
        beforeEach(() => {
          document.querySelector("html").innerHTML = `
            <head></head>

            <body>
              <div data-ui="devtools(environment: prototype, viewPath: /foo)"></div>
            </body>
          `;

          pw.Component.init(document.querySelector("html"));
          pw.Component.instances[0].transition("restarting");

          window.localStorage.setItem(
            `pw:devtools-view-path-mapping:/foo`, "/foo/bar"
          );
        });

        test("sets the document location to the mapping for the view path", () => {
          window.location.assign = jest.fn();
          pw.broadcast("pw:socket:connected", { config: {} });
          expect(window.location.assign).toHaveBeenCalledWith("/foo/bar");
        });
      });
    });
  });
});

