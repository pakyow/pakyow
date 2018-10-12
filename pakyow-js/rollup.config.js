import node from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";

export default [
  {
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
      file: "/Users/bryanp/src/pakyow/pw1/frontend/assets/packs/vendor/pakyow@1.0.0-alpha.5.js",
      format: "umd",
      name: "pw"
    }
  },

  {
    input: "src/components/socket",
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
      file: "/Users/bryanp/src/pakyow/pw1/frontend/assets/packs/vendor/pakyow@1.0.0-alpha.5__socket.js",
      format: "esm"
    }
  }
];
