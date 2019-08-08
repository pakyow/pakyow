require("../support/helpers/setup.js");
require("../support/helpers/components.js");

require("../../../src/components/socket.js");

describe("socket", () => {
  beforeEach(() => {
    document.querySelector("html").innerHTML = `
      <head>
        <meta name="pw-socket" data-ui="socket(endpoint: ws://localhost/pw-socket?id=4242)">
      </head>

      <body>
      </body>
    `;
  });

  describe("beat", () => {
    test("sends a beat", () => {
      let send = jest.fn();
      pw.Component.init(document.querySelector("html"));
      pw.Component.instances[0].send = send;
      pw.Component.instances[0].beat();
      expect(send).toHaveBeenCalledWith("beat");
    });
  });

  describe("send", () => {
    let send = jest.fn();

    beforeEach(() => {
      pw.Component.init(document.querySelector("html"));
      pw.Component.instances[0].connection.send = send;
    });

    test("sends a stringified object through the connection", () => {
      pw.Component.instances[0].send({ foo: "bar" }, "foo");
      expect(send).toHaveBeenCalledWith("{\"type\":\"foo\",\"payload\":{\"foo\":\"bar\"}}");
    });

    test("sends with unknown type when type is not passed", () => {
      pw.Component.instances[0].send({ foo: "bar" });
      expect(send).toHaveBeenCalledWith("{\"type\":\"unknown\",\"payload\":{\"foo\":\"bar\"}}");
    });
  });
});
