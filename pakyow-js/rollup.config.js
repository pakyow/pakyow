import node from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";

export default [
  {
    input: "index",
    plugins: [
      node(), babel()
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
      node(), babel()
    ],
    output: {
      extend: true,
      file: "dist/components/confirmable.js",
      format: "esm"
    }
  },
  {
    input: "src/components/form",
    plugins: [
      node(), babel()
    ],
    output: {
      extend: true,
      file: "dist/components/form.js",
      format: "esm"
    }
  },
  {
    input: "src/components/freshener",
    plugins: [
      node(), babel()
    ],
    output: {
      extend: true,
      file: "dist/components/freshener.js",
      format: "esm"
    }
  },
  {
    input: "src/components/navigable",
    plugins: [
      node(), babel()
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
      node(), babel()
    ],
    output: {
      extend: true,
      file: "dist/components/socket.js",
      format: "esm"
    }
  }
];
