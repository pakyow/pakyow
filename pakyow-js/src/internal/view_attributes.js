import {default as SetAttribute} from "./attributes/set";
import {default as HashAttribute} from "./attributes/hash";
import {default as BooleanAttribute} from "./attributes/boolean";
import {default as StringAttribute} from "./attributes/string";

const attributeTypeSet = "set";
const attributeTypeHash = "hash";
const attributeTypeBoolean = "boolean";
const attributeTypeDefault = "string";

const attributeTypes = {
  class: attributeTypeSet,
  style: attributeTypeHash,
  selected: attributeTypeBoolean,
  checked: attributeTypeBoolean,
  disabled: attributeTypeBoolean,
  readonly: attributeTypeBoolean,
  multiple: attributeTypeBoolean
};

const attributeClasses = {};
attributeClasses[attributeTypeSet] = SetAttribute;
attributeClasses[attributeTypeHash] = HashAttribute;
attributeClasses[attributeTypeBoolean] = BooleanAttribute;
attributeClasses[attributeTypeDefault] = StringAttribute;

export default class {
  constructor(view) {
    this.view = view;
  }

  get(attribute) {
    let type = attributeTypes[attribute] || attributeTypeDefault;
    return new attributeClasses[type](attribute, this.view);
  }

  set(attribute, value) {
    let attributeType = attributeTypes[attribute];

    if (attributeType === attributeTypeHash) {
      this.get(attribute).replace(value);
    } else if (attributeType === attributeTypeSet) {
      this.view.node.setAttribute(attribute, value.join(" "));
    } else if (attributeType === attributeTypeBoolean) {
      if (value) {
        this.view.node.setAttribute(attribute, attribute);
      } else {
        this.view.node.removeAttribute(attribute);
      }
    } else {
      this.view.node.setAttribute(attribute, value);
    }
  }
}
