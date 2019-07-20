require("mutationobserver-shim");
global.MutationObserver = window.MutationObserver;

afterEach(() => {
  jest.clearAllMocks();
});

afterEach(() => {
  while(pw.Component.instances.length > 0) {
    pw.Component.instances.pop();
  }

  pw.Component.clearObserver();
});
