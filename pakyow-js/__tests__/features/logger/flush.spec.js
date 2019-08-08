require("../support/helpers/setup.js");

describe("logger", () => {
  describe("flush", () => {
    let socket = {
      send: jest.fn()
    };

    beforeEach(() => {
      pw.logger.log("unknown", "log", "foo");
      pw.logger.log("error", "error", "bar");

      pw.server.socket = socket;
      pw.server.reachable = true;
    });

    afterEach(() => {
      socket.send.mockClear();
    });

    test("sends each unsent message", () => {
      pw.logger.flush();

      expect(socket.send.mock.calls).toEqual(
        [
          [{ severity: "unknown", message: "foo" }, "log"],
          [{ severity: "error", message: "bar" }, "log"]
        ]
      );
    });

    describe("flushed again", () => {
      test("does not send anything", () => {
        pw.logger.flush();
        socket.send.mockClear();

        expect(socket.send).not.toHaveBeenCalled();
        pw.logger.flush();
      });
    });
  });
});
