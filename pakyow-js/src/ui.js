var modifierKeyPressed = false;

document.documentElement.addEventListener("keydown", (event) => {
  if (event.metaKey || event.crtlKey || event.altKey || event.shiftKey) {
    modifierKeyPressed = true;
  }
});

document.documentElement.addEventListener("keyup", (event) => {
  if (!event.metaKey && !event.crtlKey && !event.altKey && !event.shiftKey) {
    modifierKeyPressed = false;
  }
});

var currentNavigator;
export default class {
  static get modifierKeyPressed() {
    return modifierKeyPressed;
  }

  static navigableVia(navigatorObject) {
    currentNavigator = navigatorObject;
  }

  static visit(url, xhr) {
    if (currentNavigator) {
      currentNavigator.visit(url, xhr);
    } else {
      document.location = url;
    }
  }
}
