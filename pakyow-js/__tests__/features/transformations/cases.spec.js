const fs = require("fs");
const path = require("path");
const dirs = p => fs.readdirSync(p).filter(f => fs.statSync(path.join(p, f)).isDirectory());

const { JSDOM } = require("jsdom");

global.pw = require("../../../src/index");
import {default as Transformer} from "../../../src/internal/transformer";

const caseDir = "__tests__/features/transformations/support/cases";

const removeWhitespace = function (string) {
  return string.replace(/\n/g, "").replace(/[ ]+\</g, "<").replace(/\>[ ]+\</g, "><").replace(/\>[ ]+/g, ">");
}

const comparable = function (dom) {
  // remove the templates from the result (making it easier to compare)
  for (let script of dom.querySelectorAll("script")) {
    script.parentNode.removeChild(script)
  }

  // strip all whitespace from the result (making it easier to compare)
  return removeWhitespace(
    dom.querySelector("body").outerHTML
  );
}

describe("transformations", () => {
  for (let caseName of dirs(caseDir)) {
    if (caseName != "updating_an_object_in_a_way_that_presents_a_new_prop") {
      // continue;
    }

    test(`case: ${caseName}`, () => {
      let initial = fs.readFileSync(
        path.join(caseDir, caseName, "initial.html"),
        "utf8"
      );

      let result = fs.readFileSync(
        path.join(caseDir, caseName, "result.html"),
        "utf8"
      );

      let transformations = JSON.parse(
        fs.readFileSync(
          path.join(caseDir, caseName, "transformations.json"),
          "utf8"
        )
      );

      let metadata = JSON.parse(
        fs.readFileSync(
          path.join(caseDir, caseName, "metadata.json"),
          "utf8"
        )
      );

      jsdom.reconfigure({
        url: "http://localhost" + metadata.path
      });

      let initialDOM = new JSDOM(initial);
      let resultDOM = new JSDOM(result);

      // set the top level transformation id
      document.querySelector("html").setAttribute("data-t", initialDOM.window.document.querySelector("html").getAttribute("data-t"))

      // replace the rest of the document
      document.querySelector("html").innerHTML = initialDOM.window.document.querySelector("html").innerHTML;

      // apply the transformations
      for (let transformation of transformations) {
        new Transformer(transformation);
      }

      // finally, make the assertion
      var HtmlDiffer = require('html-differ').HtmlDiffer;
      var htmlDiffer = new HtmlDiffer({});
      var htmlLogger = require('html-differ/lib/logger');

      var diff = htmlDiffer.diffHtml(
        comparable(document), comparable(resultDOM.window.document)
       );

      expect(
        htmlLogger.getDiffText(diff)
       ).toEqual("");
    });
  }
});
