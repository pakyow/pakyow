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
      file: "dist/pakyow.js",
      format: "umd",
      name: "pw"
    }
  },
  {
    input: "src/components/confirmable",
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
      file: "dist/components/confirmable.js",
      format: "esm"
    }
  },
  {
    input: "src/components/navigable",
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
      file: "dist/components/navigable.js",
      format: "esm"
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
      file: "dist/components/socket.js",
      format: "esm"
    }
  }
];
