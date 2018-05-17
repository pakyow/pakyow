import node from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";

export default {
  input: "index",
  plugins: [
    node(),
    babel({
      plugins: [
        "external-helpers"
      ]
    })
  ],
  output: {
    extend: true,
    file: "dist/pakyow.js",
    format: "umd",
    name: "pw"
  }
};
