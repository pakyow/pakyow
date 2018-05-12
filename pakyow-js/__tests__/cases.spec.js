const fs = require("fs");
const path = require("path");
const dirs = p => fs.readdirSync(p).filter(f => fs.statSync(path.join(p, f)).isDirectory());

const jsdom = require("jsdom");
const { JSDOM } = jsdom;

global.pw = require("../src/index");
import {default as Transformer} from "../src/internal/transformer";

const caseDir = "__tests__/support/cases";

const removeWhitespace = function (string) {
  return string.replace(/\n/g, "").replace(/[\t ]+\</g, "<").replace(/\>[\t ]+\</g, "><").replace(/\>[\t ]+$/g, ">");
}

for (let caseName of dirs(caseDir)) {
  // if (caseName != "empty_to_data") {
  //   continue;
  // }
  test(`case: ${caseName}`, () => {
    let initial = fs.readFileSync(
      path.join(caseDir, caseName, "initial.html"),
      "utf8"
    );

    let result = removeWhitespace(fs.readFileSync(
      path.join(caseDir, caseName, "result.html"),
      "utf8"
    ));

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
    new Transformer(transformation);

    // remove the templates from the result (making it easier to compare)
    for (let script of document.querySelectorAll("script")) {
      script.parentNode.removeChild(script)
    }

    // strip all whitespace from the result (making it easier to compare)
    let actual = removeWhitespace(document.querySelector("body").outerHTML);

    // finally, make the assertion
    expect(actual).toEqual(result);
  });
}
