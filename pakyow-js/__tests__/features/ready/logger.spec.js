require("../support/helpers/setup.js");

describe("ready", () => {
  let ready = () => {
    require("../../../index");
    document.dispatchEvent(
      new CustomEvent("DOMContentLoaded")
    );
  }

  describe("logger", () => {
    test("installs the logger", () => {
      let spy = jest.spyOn(pw.logger, "install");
      ready();
      expect(spy).toHaveBeenCalled();
    });

    describe("global socket connects", () => {
      test("flushes the logger", () => {
        ready();
        let spy = jest.spyOn(pw.logger, "flush");
        pw.broadcast("pw:socket:connected", { config: { global: true } });
        expect(spy).toHaveBeenCalled();
      });
    });

    describe("non-global socket connects", () => {
      test("does not flush the logger", () => {
        ready();
        let spy = jest.spyOn(pw.logger, "flush");
        pw.broadcast("pw:socket:connected", { config: {} });
        expect(spy).not.toHaveBeenCalled();
      });
    });
  });
});
