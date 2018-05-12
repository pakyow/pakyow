import {default as ViewSetAttribute} from "./view_set_attribute";

export default class {
  constructor(viewSet) {
    this.viewSet = viewSet;
  }

  get(attribute) {
    return new ViewSetAttribute(
      this.viewSet.views.map((view) => {
        return view.attributes().get(attribute);
      }
    ));
  }

  set(attribute, value) {
    for (let view of this.viewSet.views) {
      view.attributes().set(attribute, value);
    }
  }
}
