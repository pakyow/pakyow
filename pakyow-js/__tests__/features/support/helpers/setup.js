require("mutationobserver-shim");
global.MutationObserver = window.MutationObserver;
global.pw = require("../../../../src/index");
