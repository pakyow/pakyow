require("./support/helpers/setup.js");

describe("logger", () => {
  describe("log", () => {
    let socket = {
      send: jest.fn()
    };

    let perform = () => {
      pw.logger.log("error", "error", "foo", "bar");
    };

    afterEach(() => {
      socket.send.mockClear();
    });

    describe("socket is available", () => {
      beforeEach(() => {
        pw.server.socket = socket;
      });

      describe("server is reachable", () => {
        beforeEach(() => {
          pw.server.reachable = true;
        });

        test("sends each message", () => {
          perform();

          expect(socket.send.mock.calls).toEqual(
            [
              [{ severity: "error", message: "foo" }, "log"],
              [{ severity: "error", message: "bar" }, "log"]
            ]
          );
        });
      });

      describe("server is unreachable", () => {
        test("does not log", () => {
          expect(socket.send).not.toHaveBeenCalled();
          perform();
        });
      });
    });

    describe("socket is unavailable", () => {
      test("does not log", () => {
        expect(socket.send).not.toHaveBeenCalled();
        perform();
      });
    });
  });
});
