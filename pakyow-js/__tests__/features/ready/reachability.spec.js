require("../support/helpers/setup.js");

describe("ready", () => {
  let ready = () => {
    require("../../../index");
    document.dispatchEvent(
      new CustomEvent("DOMContentLoaded")
    );
  }

  describe("reachability", () => {
    describe("global socket connects", () => {
      test("sets the server as reachable", () => {
        ready();
        expect(pw.server.reachable).toEqual(false);
        pw.broadcast("pw:socket:connected", { config: { global: true } });
        expect(pw.server.reachable).toEqual(true);
      });
    });

    describe("global socket disconnects", () => {
      beforeEach(() => {
        ready();
        pw.broadcast("pw:socket:connected", { config: { global: true } });
      });

      test("sets the server as unreachable", () => {
        expect(pw.server.reachable).toEqual(true);
        pw.broadcast("pw:socket:disconnected", { config: { global: true } });
        expect(pw.server.reachable).toEqual(false);
      });
    });

    describe("global socket disappears", () => {
      beforeEach(() => {
        ready();
        pw.broadcast("pw:socket:connected", { config: { global: true } });
      });

      test("sets the server as unreachable", () => {
        expect(pw.server.reachable).toEqual(true);
        pw.broadcast("pw:socket:disappeared", { config: { global: true } });
        expect(pw.server.reachable).toEqual(false);
      });
    });

    describe("non-global socket connects", () => {
      test("does not set the server as reachable", () => {
        ready();
        expect(pw.server.reachable).toEqual(false);
        pw.broadcast("pw:socket:connected", { config: {} });
        expect(pw.server.reachable).toEqual(false);
      });
    });

    describe("non-global socket disconnects", () => {
      beforeEach(() => {
        ready();
        pw.broadcast("pw:socket:connected", { config: { global: true } });
      });

      test("does not set the server as unreachable", () => {
        expect(pw.server.reachable).toEqual(true);
        pw.broadcast("pw:socket:disconnected", { config: {} });
        expect(pw.server.reachable).toEqual(true);
      });
    });

    describe("non-global socket disappears", () => {
      beforeEach(() => {
        ready();
        pw.broadcast("pw:socket:connected", { config: { global: true } });
      });

      test("does not set the server as unreachable", () => {
        expect(pw.server.reachable).toEqual(true);
        pw.broadcast("pw:socket:disappeared", { config: {} });
        expect(pw.server.reachable).toEqual(true);
      });
    });
  });
});
