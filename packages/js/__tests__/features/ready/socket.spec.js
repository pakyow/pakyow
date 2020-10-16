require("../support/helpers/setup.js");

describe("ready", () => {
  let ready = () => {
    require("../../../index");
    document.dispatchEvent(
      new CustomEvent("DOMContentLoaded")
    );
  }

  describe("socket", () => {
    let globalSocket = { config: { global: true } };

    describe("global socket connects", () => {
      test("sets the server socket", () => {
        ready();
        expect(pw.server.socket).toEqual(undefined);
        pw.broadcast("pw:socket:connected", globalSocket);
        expect(pw.server.socket).toBe(globalSocket);
      });
    });

    describe("global socket disconnects", () => {
      beforeEach(() => {
        ready();
        pw.broadcast("pw:socket:connected", globalSocket);
      });

      test("unsets the server socket", () => {
        expect(pw.server.socket).toBe(globalSocket);
        pw.broadcast("pw:socket:disconnected", globalSocket);
        expect(pw.server.socket).toEqual(null);
      });
    });

    describe("non-global socket connects", () => {
      test("does not set the server socket", () => {
        pw.broadcast("pw:socket:connected", { config: {} });
        expect(pw.server.socket).toEqual(null);
      });
    });

    describe("non-global socket disconnects", () => {
      beforeEach(() => {
        ready();
        pw.broadcast("pw:socket:connected", globalSocket);
      });

      test("does not unset the server socket", () => {
        expect(pw.server.socket).toBe(globalSocket);
        pw.broadcast("pw:socket:disconnected", { config: {} });
        expect(pw.server.socket).toBe(globalSocket);
      });
    });
  });
});
