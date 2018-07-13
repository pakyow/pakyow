export default function(name, object) {
  var component = pw.Component.create();
  Object.getOwnPropertyNames(object).forEach((method) => {
    component.prototype[method] = object[method];
  });

  pw.Component.register(name, component);
};
