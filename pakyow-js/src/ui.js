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

export default class {
  static get modifierKeyPressed() {
    return modifierKeyPressed;
  }
}
