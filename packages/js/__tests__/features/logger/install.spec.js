require("../support/helpers/setup.js");

describe("logger", () => {
  describe("install", () => {
    let logSpy;

    let consoleLogSpy = jest.fn();
    let consoleDebugSpy = jest.fn();
    let consoleInfoSpy = jest.fn();
    let consoleWarnSpy = jest.fn();
    let consoleErrorSpy = jest.fn();
    let consoleTraceSpy = jest.fn();

    beforeEach(() => {
      logSpy = jest.spyOn(pw.logger, "log");

      console.log = consoleLogSpy;
      console.debug = consoleDebugSpy;
      console.info = consoleInfoSpy;
      console.warn = consoleWarnSpy;
      console.error = consoleErrorSpy;
      console.trace = consoleTraceSpy;

      pw.logger.install();
    });

    afterEach(() => {
      logSpy.mockClear();

      consoleLogSpy.mockClear();
      consoleDebugSpy.mockClear();
      consoleInfoSpy.mockClear();
      consoleWarnSpy.mockClear();
      consoleErrorSpy.mockClear();
      consoleTraceSpy.mockClear();
    });

    describe("log", () => {
      test("logs with the logger", () => {
        console.log("foo", "bar");
        expect(logSpy).toHaveBeenCalledWith("unknown", "log", "foo", "bar");
      });

      test("calls the original console.log method", () => {
        console.log("foo", "bar");
        expect(consoleLogSpy).toHaveBeenCalledWith("foo", "bar");
      });
    });

    describe("debug", () => {
      test("logs with the logger", () => {
        console.debug("foo", "bar");
        expect(logSpy).toHaveBeenCalledWith("debug", null, "foo", "bar");
      });

      test("calls the original console.debug method", () => {
        console.debug("foo", "bar");
        expect(consoleDebugSpy).toHaveBeenCalledWith("foo", "bar");
      });
    });

    describe("info", () => {
      test("logs with the logger", () => {
        console.info("foo", "bar");
        expect(logSpy).toHaveBeenCalledWith("info", null, "foo", "bar");
      });

      test("calls the original console.info method", () => {
        console.info("foo", "bar");
        expect(consoleInfoSpy).toHaveBeenCalledWith("foo", "bar");
      });
    });

    describe("warn", () => {
      test("logs with the logger", () => {
        console.warn("foo", "bar");
        expect(logSpy).toHaveBeenCalledWith("warn", null, "foo", "bar");
      });

      test("calls the original console.warn method", () => {
        console.warn("foo", "bar");
        expect(consoleWarnSpy).toHaveBeenCalledWith("foo", "bar");
      });
    });

    describe("error", () => {
      test("logs with the logger", () => {
        console.error("foo", "bar");
        expect(logSpy).toHaveBeenCalledWith("error", null, "foo", "bar");
      });

      test("calls the original console.error method", () => {
        console.error("foo", "bar");
        expect(consoleErrorSpy).toHaveBeenCalledWith("foo", "bar");
      });
    });

    describe("unknown console methods", () => {
      test("calls the original console method", () => {
        console.trace();
        expect(consoleTraceSpy).toHaveBeenCalled();
      });
    });
  });
});
