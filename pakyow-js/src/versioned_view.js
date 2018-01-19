import {default as View} from "./view";

export default class extends View {
  constructor(versions) {
    var versionedView;
    for(let view of versions) {
      if (view.version == "default") {
        versionedView = view;
        break;
      }
    }

    if (!versionedView) { versionedView = versions[0] }

    super(versionedView.node);
  }
}
