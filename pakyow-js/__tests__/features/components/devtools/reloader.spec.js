require("../../support/helpers/setup.js");
require("../../support/helpers/components.js");

require("../../../../src/components/devtools.js");

describe("devtools:reloader", () => {
  describe("ui becomes stale", () => {
    beforeEach(() => {
      document.querySelector("html").innerHTML = `
        <head></head>

        <body>
          <div data-ui="devtools:reloader"></div>
        </body>
      `;

      pw.Component.init(document.querySelector("html"));
    });

    test("reloads the document location", () => {
      let spy = jest.spyOn(document.location, "reload").mockImplementation(() => {});
      pw.broadcast("pw:ui:stale");
      expect(spy).toHaveBeenCalled();
    });
  });
});
