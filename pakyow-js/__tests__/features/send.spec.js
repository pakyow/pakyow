global.pw = require("../../src/index");
import XMLHttpRequest from "./support/mocks/xhr";
jest.mock("./support/mocks/xhr")

beforeEach(() => {
  XMLHttpRequest.mockClear();
  global.XMLHttpRequest = XMLHttpRequest;
});

describe("sending to the server", () => {
  test("sends", () => {
    pw.send("/");

    expect(XMLHttpRequest.mock.instances[0].open.mock.calls.length).toBe(1);
  });

  test("defaults to GET", () => {
    pw.send("/");

    expect(XMLHttpRequest.mock.instances[0].open.mock.calls[0][0]).toEqual(
      "GET"
    );
  });

  test("uses the passed url", () => {
    pw.send("/foobar");

    expect(XMLHttpRequest.mock.instances[0].open.mock.calls[0][1]).toEqual(
      expect.stringContaining("/foobar")
    );
  });

  test("cache busts by default", () => {
    pw.send("/");

    expect(XMLHttpRequest.mock.instances[0].open.mock.calls[0][1]).toEqual(
      expect.stringMatching(/\?_=\d{13}/)
    );
  });

  test("sets the pw ui header", () => {
    pw.send("/");

    expect(XMLHttpRequest.mock.instances[0].setRequestHeader.mock.calls[0]).toEqual(
      ["pw-ui", pw.version]
    );
  });

  test("sets the accept header", () => {
    pw.send("/");

    expect(XMLHttpRequest.mock.instances[0].setRequestHeader.mock.calls[1]).toEqual(
      ["accept", "text/html"]
    );
  });

  describe("200 response", () => {
    test("calls success callback with response, response text", () => {
      let success = jest.fn();
      let xhr = pw.send("/", { success: success });
      xhr.status = 200;
      xhr.readyState = 4;
      xhr.responseText = "foo";
      xhr.onreadystatechange();

      expect(success.mock.calls.length).toBe(1);
      expect(success.mock.calls[0]).toEqual([xhr, "foo"]);
    });

    test("does not call error callback", () => {
      let error = jest.fn();
      let xhr = pw.send("/", { error: error });
      xhr.status = 200;
      xhr.readyState = 4;
      xhr.onreadystatechange();

      expect(error.mock.calls.length).toBe(0);
    });

    test("calls complete", () => {
      let complete = jest.fn();
      let xhr = pw.send("/", { complete: complete });
      xhr.status = 200;
      xhr.readyState = 4;
      xhr.responseText = "foo";
      xhr.onreadystatechange();

      expect(complete.mock.calls.length).toBe(1);
      expect(complete.mock.calls[0]).toEqual([xhr]);
    });

    xtest("broadcasts with success callback", () => {});
    xtest("broadcasts without success callback", () => {});
  });

  describe("500 response", () => {
    test("calls error callback with response, status text", () => {
      let error = jest.fn();
      let xhr = pw.send("/", { error: error });
      xhr.status = 500;
      xhr.readyState = 4;
      xhr.statusText = "foo";
      xhr.onreadystatechange();

      expect(error.mock.calls.length).toBe(1);
      expect(error.mock.calls[0]).toEqual([xhr, "foo"]);
    });

    test("does not call success callback", () => {
      let success = jest.fn();
      let xhr = pw.send("/", { success: success });
      xhr.status = 500;
      xhr.readyState = 4;
      xhr.onreadystatechange();

      expect(success.mock.calls.length).toBe(0);
    });

    test("calls complete", () => {
      let complete = jest.fn();
      let xhr = pw.send("/", { complete: complete });
      xhr.status = 500;
      xhr.readyState = 4;
      xhr.statusText = "foo";
      xhr.onreadystatechange();

      expect(complete.mock.calls.length).toBe(1);
      expect(complete.mock.calls[0]).toEqual([xhr]);
    });

    xtest("broadcasts with error callback", () => {});
    xtest("broadcasts without error callback", () => {});
  });

  describe("sending with data", () => {
    test("sets the content type to application/json", () => {
      pw.send("/", { data: { foo: "bar" } });

      expect(XMLHttpRequest.mock.instances[0].setRequestHeader.mock.calls[1]).toEqual(
        ["content-type", "application/json"]
      );
    });

    test("passes data as stringified json", () => {
      pw.send("/", { data: { foo: "bar" } });

      expect(XMLHttpRequest.mock.instances[0].send.mock.calls[0]).toEqual(
        ["{\"foo\":\"bar\"}"]
      );
    });
  });

  describe("sending with headers", () => {
    test("sets each header", () => {
      pw.send("/", {
        headers: {
          "content-length": 0,
          "content-type": "text/xml"
        }
      });

      expect(XMLHttpRequest.mock.instances[0].setRequestHeader.mock.calls[1]).toEqual(
        ["content-length", 0]
      );

      expect(XMLHttpRequest.mock.instances[0].setRequestHeader.mock.calls[2]).toEqual(
        ["content-type", "text/xml"]
      );
    });
  });

  describe("disabling cache busting", () => {
    test("does not cache bust", () => {
      pw.send("/", { cache: true });

      expect(XMLHttpRequest.mock.instances[0].open.mock.calls[0][1]).not.toEqual(
        expect.stringMatching(/\?_=\d{13}/)
      );
    });
  });

  describe("authenticity for non-get requests", () => {
    test("when present in the dom, it adds the token to the request data", () => {
      document.querySelector("html").innerHTML = `
        <head>
          <meta name="pw-authenticity-token" content="66c2ab941b41171c70135c59f0bb32ef4f76ec712ae3f02f:/ee+O8auZoBjxbbziOJEp7cliHqbzOtk1vmIi7k4Spw=">
          <meta name="pw-authenticity-param" content="authenticity_token">
        </head>
        <body>
        </body>
      `;

      pw.send("/", { method: "POST" });

      expect(XMLHttpRequest.mock.instances[0].send.mock.calls[0][0]).toEqual(
        "{\"authenticity_token\":\"66c2ab941b41171c70135c59f0bb32ef4f76ec712ae3f02f:/ee+O8auZoBjxbbziOJEp7cliHqbzOtk1vmIi7k4Spw=\"}"
      );
    });

    test("does not override an existing token", () => {
      document.querySelector("html").innerHTML = `
        <head>
          <meta name="pw-authenticity-token" content="66c2ab941b41171c70135c59f0bb32ef4f76ec712ae3f02f:/ee+O8auZoBjxbbziOJEp7cliHqbzOtk1vmIi7k4Spw=">
          <meta name="pw-authenticity-param" content="authenticity_token">
        </head>
        <body>
        </body>
      `;

      pw.send("/", { method: "POST", data: { authenticity_token: "foo" } });

      expect(XMLHttpRequest.mock.instances[0].send.mock.calls[0][0]).toEqual(
        "{\"authenticity_token\":\"foo\"}"
      );
    });

    test("when not present in the dom, it still sends the request", () => {
      pw.send("/", { method: "POST" });
      expect(XMLHttpRequest.mock.instances[0].send.mock.calls.length).toBe(1);
    });
  });

  describe("form data", () => {
    test("sends with form data", () => {
      var formData = new FormData();
      pw.send("/", { method: "POST", data: formData });
      expect(XMLHttpRequest.mock.instances[0].send.mock.calls[0][0]).toEqual(formData);
    });
  });
});
