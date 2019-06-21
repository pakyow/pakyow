export default function(name, object) {
  var component = pw.Component.create();

  for (let method in Object.getOwnPropertyDescriptors(object)) {
    Object.defineProperty(component.prototype, method, Object.getOwnPropertyDescriptor(object, method));
  }

  pw.Component.register(name, component);
};
