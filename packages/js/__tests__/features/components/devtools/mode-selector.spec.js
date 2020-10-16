require("../../support/helpers/setup.js");
require("../../support/helpers/components.js");

require("../../../../src/components/devtools.js");

describe("devtools:mode-selector", () => {
  describe("version is changed", () => {
    beforeEach(() => {
      document.querySelector("html").innerHTML = `
        <head></head>

        <body>
          <select data-ui="devtools:mode-selector">
          <option value="one">one</option>
            <option value="two">two</option>
           </select>
        </body>
      `;

      pw.Component.init(document.querySelector("html"));
    });

    test("updates the window location", () => {
      pw.Component.instances[0].node.value = "two";
      pw.Component.instances[0].node.dispatchEvent(new Event("change"));
      expect(window.location.assign).toHaveBeenCalledWith("/?modes[]=two");
    });
  });
});
