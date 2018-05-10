const fs = require("fs");
const path = require("path");
const dirs = p => fs.readdirSync(p).filter(f => fs.statSync(path.join(p, f)).isDirectory());

const jsdom = require("jsdom");
const { JSDOM } = jsdom;

global.pw = require("../src/index");

const caseDir = "__tests__/support/cases";

for (let caseName of dirs(caseDir)) {
  test(`case: ${caseName}`, () => {
    let initial = fs.readFileSync(
      path.join(caseDir, caseName, "initial.html"),
      "utf8"
    );

    let result = fs.readFileSync(
      path.join(caseDir, caseName, "result.html"),
      "utf8"
    );

    let transformation = JSON.parse(
      fs.readFileSync(
        path.join(caseDir, caseName, "transformation.json"),
        "utf8"
      )
    );

    let dom = new JSDOM(initial);

    // set the top level transformation id
    document.querySelector("html").setAttribute("data-t", dom.window.document.querySelector("html").getAttribute("data-t"))

    // replace the rest of the document
    document.querySelector("html").innerHTML = dom.window.document.querySelector("html").innerHTML;

    // apply the transformation
    new pw.Transformer(transformation);

    // remove the templates from the result (making it easier to compare)
    for (let script of document.querySelectorAll("script")) {
      script.parentNode.removeChild(script)
    }

    // strip all whitespace from the result (making it easier to compare)
    let actual = document.querySelector("body").outerHTML.replace(/\n/g, "").replace(/[\t ]+\</g, "<").replace(/\>[\t ]+\</g, "><").replace(/\>[\t ]+$/g, ">");

    // finally, make the assertion
    expect(actual).toEqual(result);
  });
}
