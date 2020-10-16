require("../../support/helpers/setup.js");
require("../../support/helpers/components.js");

require("../../../../src/components/devtools.js");

describe("devtools:environment", () => {
  describe("clicking on the environment", () => {
    beforeEach(() => {
      document.querySelector("html").innerHTML = `
        <head></head>

        <body>
          <div data-ui="devtools:environment"></div>
        </body>
      `;

      pw.Component.init(document.querySelector("html"));
    });

    test("bubbles devtools:toggle-environment", () => {
      let spy = jest.spyOn(pw.Component.instances[0], "bubble");
      pw.Component.instances[0].node.click();
      expect(spy).toHaveBeenCalledWith("devtools:toggle-environment");
    });
  });
});
