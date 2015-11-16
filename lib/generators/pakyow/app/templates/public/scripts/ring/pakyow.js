var pw = {
  version: '0.1.1'
};

(function() {
pw.util = {
  guid: function () {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8);
      return v.toString(16);
    });
  },

  dup: function (object) {
    return JSON.parse(JSON.stringify(object));
  }
};
var fns = [];

pw.init = {
  register: function (fn) {
    fns.push(fn);
  }
};

document.addEventListener("DOMContentLoaded", function() {
  fns.forEach(function (fn) {
    fn();
  });
});
var sigAttrs = ['data-scope', 'data-prop'];
var valuelessTags = ['SELECT'];
var selfClosingTags = ['AREA', 'BASE', 'BASEFONT', 'BR', 'HR', 'INPUT', 'IMG', 'LINK', 'META'];

pw.node = {
  // returns the value of the node
  value: function (node) {
    if (node.tagName === 'INPUT') {
      if (node.type === 'checkbox') {
        if (node.checked) {
          return node.value ? node.value : true;
        } else {
          return false;
        }
      }

      return node.value;
    } else if (node.tagName === 'TEXTAREA') {
      return node.value;
    } else if (node.tagName === 'SELECT') {
      return node.value;
    }

    return node.textContent.trim();
  },

  /*
    Returns a representation of the node's state. Example:

    <div data-scope="list" data-id="1">
      <div data-scope="task" data-id="1">
        <label data-prop="desc">
          foo
        </label>
      </div>
    </div>

    [ [ { node: ..., id: '1', scope: 'list' }, [ { node: ..., id: '1', scope: 'task' }, [ { node: ..., prop: 'body' } ] ] ] ]
  */

  significant: function(node, arr) {
    if(node === document) {
      node = document.getElementsByTagName('body')[0];
    }

    if(arr === undefined) {
      arr = [];
    }

    var sig, nArr;

    if(sig = pw.node.isSignificant(node)) {
      nArr = [];
      arr.push([{ node: sig[0], type: sig[1] }, nArr]);
    } else {
      nArr = arr;
    }

    pw.node.toA(node.children).forEach(function (child) {
      pw.node.significant(child, nArr);
    });

    return arr;
  },

  // returns node and an indication of it's significance
  // (e.g value of scope/prop); returns false otherwise
  isSignificant: function(node) {
    var attr = sigAttrs.find(function (a) {
      return node.hasAttribute(a);
    });

    if (attr) {
      return [node, attr.split('-')[1]];
    } else {
      return false;
    }
  },

  mutable: function (node) {
    pw.node.significant(node).flatten().filter(function (n) {
      return pw.node.isMutable(n.node);
    }).map(function (n) {
      return n.node;
    });
  },

  // returns true if the node can mutate via interaction
  isMutable: function(node) {
    var tag = node.tagName;
    return tag === 'FORM' || (tag === 'INPUT' && !node.disabled);
  },

  // triggers event name on node with data
  trigger: function (evtName, node, data) {
    var evt = document.createEvent('Event');
    evt.initEvent(evtName, true, true);

    node._evtData = data;
    node.dispatchEvent(evt);
  },

  // replaces an event listener's callback for node by name
  replaceEventListener: function (eventName, node, cb) {
    node.removeEventListener(eventName);
    node.addEventListener(eventName, cb);
  },

  inForm: function (node) {
    if (node.tagName === 'FORM') {
      return true;
    }

    var next = node.parentNode;
    if (next !== document) {
      return pw.node.inForm(next);
    }
  },

  // finds and returns component for node
  component: function (node) {
    if (node.getAttribute('data-ui')) {
      return node;
    }

    var next = node.parentNode;
    if (next !== document) {
      return pw.node.component(next);
    }
  },

  // finds and returns scope for node
  scope: function (node) {
    if (node.getAttribute('data-scope')) {
      return node;
    }

    var next = node.parentNode;
    if (next !== document) {
      return pw.node.scope(next);
    }
  },

  // returns the name of the scope for node
  scopeName: function (node) {
    if (node.getAttribute('data-scope')) {
      return node.getAttribute('data-scope');
    }

    var next = node.parentNode;
    if (next !== document) {
      return pw.node.scopeName(next);
    }
  },

  // finds and returns prop for node
  prop: function (node) {
    if (node.getAttribute('data-prop')) {
      return node;
    }

    var next = node.parentNode;
    if (next !== document) {
      return pw.node.prop(next);
    }
  },

  // returns the name of the prop for node
  propName: function (node) {
    if (node.getAttribute('data-prop')) {
      return node.getAttribute('data-prop');
    }

    var next = node.parentNode;
    if (next !== document) {
      return pw.node.propName(next);
    }
  },

  // returns the name of the version for node
  versionName: function (node) {
    if (node.hasAttribute('data-version')) {
      return node.getAttribute('data-version');
    }
  },

  // creates a context in which view manipulations can occur
  with: function(node, cb) {
    cb.call(node);
  },

  for: function(node, data, cb) {
    if (pw.node.isNodeList(node)) {
      node = pw.node.toA(node);
    }

    node = Array.ensure(node);
    data = Array.ensure(data);

    node.forEach(function (e, i) {
      cb.call(e, data[i]);
    });
  },

  match: function(node, data) {
    if (pw.node.isNodeList(node)) {
      node = pw.node.toA(node);
    }

    node = Array.ensure(node);
    data = Array.ensure(data);

    var collection = data.reduce(function (c, dm, i) {
      // get the view, or if we're out just use the last one
      var v = n[i] || n[n.length - 1];

      var dv = v.cloneNode(true);
      v.parentNode.insertBefore(dv);
      return c.concat([dv])
    }, []);

    node.forEach(function (o) {
      o.parentNode.removeChild(o);
    });

    return collection;
  },

  repeat: function(node, data, cb) {
    pw.node.for(pw.node.match(node, data), data, cb);
  },

  // binds an object to a node
  bind: function (data, node, cb) {
    var scope = pw.node.findBindings(node)[0];

    pw.node.for(node, data, function(dm) {
      if (!dm) {
        return;
      }

      if(dm.id) {
        this.setAttribute('data-id', dm.id);
      }

      pw.node.bindDataToScope(dm, scope, node);

      if(!(typeof cb === 'undefined')) {
        cb.call(this, dm);
      }
    });
  },

  apply: function (data, node, cb) {
    var c = pw.node.match(node, data);
    pw.node.bind(data, c, cb);
    return c;
  },

  findBindings: function (node) {
    var bindings = [];
    pw.node.breadthFirst(node, function() {
      var o = this;

      var scope = o.getAttribute('data-scope');

      if(!scope) {
        return;
      }

      var props = [];
      pw.node.breadthFirst(o, function() {
        var so = this;

        // don't go into deeper scopes
        if(o != so && so.getAttribute('data-scope')) {
          return;
        }

        var prop = so.getAttribute('data-prop');

        if(!prop) {
          return;
        }

        props.push({
          prop: prop,
          doc: so
        });
      });

      bindings.push({
        scope: scope,
        props: props,
        doc: o,
      });
    });

    return bindings;
  },

  bindDataToScope: function (data, scope, node) {
    if(!data || !scope) {
      return;
    }

    scope['props'].forEach(function (p) {
      k = p['prop'];
      v = data[k];

      if(!v) {
        v = '';
      }

      if(typeof v === 'object') {
        pw.node.bindValueToNode(v['__content'], p['doc']);
        pw.node.bindAttributesToNode(v['__attrs'], p['doc']);
      } else {
        pw.node.bindValueToNode(v, p['doc']);
      }
    });
  },

  bindAttributesToNode: function (attrs, node) {
    var nAtrs = pw.attrs.init(pw.view.init(node));

    for(var attr in attrs) {
      var v = attrs[attr];
      if(typeof v === 'function') {
        v = v.call(node.getAttribute(attr));
      }

      if (v) {
        if (v instanceof Array) {
          v.forEach(function (attrInstruction) {
            nAtrs[attrInstruction[0]](attr, attrInstruction[1]);
          });
        } else {
          nAtrs.set(attr, v);
        }
      } else {
        nAtrs.remove(attr);
      }
    }
  },

  bindValueToNode: function (value, node) {
    if(pw.node.isTagWithoutValue(node)) {
      return;
    }

    //TODO handle other form fields (port from pakyow-presenter)
    if (node.tagName === 'INPUT' && node.type === 'checkbox') {
      if (value === true || (node.value && value === node.value)) {
        node.checked = true;
      } else {
        node.checked = false;
      }
    } else if (node.tagName === 'TEXTAREA' || pw.node.isSelfClosingTag(node)) {
      node.value = value;
    } else {
      node.innerHTML = value;
    }
  },

  isTagWithoutValue: function(node) {
    return valuelessTags.indexOf(node.tagName) != -1 ? true : false;
  },

  isSelfClosingTag: function(node) {
    return selfClosingTags.indexOf(node.tagName) != -1 ? true : false;
  },

  breadthFirst: function (node, cb) {
    var queue = [node];
    while (queue.length > 0) {
      var subNode = queue.shift();
      if (!subNode) continue;
      if(typeof subNode == "object" && "nodeType" in subNode && subNode.nodeType === 1 && subNode.cloneNode) {
        cb.call(subNode);
      }

      var children = subNode.childNodes;
      if (children) {
        for(var i = 0; i < children.length; i++) {
          queue.push(children[i]);
        }
      }
    }
  },

  isNodeList: function(nodes) {
    return typeof nodes.length !== 'undefined';
  },

  byAttr: function (node, attr, value) {
    return pw.node.all(node).filter(function (o) {
      var ov = o.getAttribute(attr);
      return ov !== null && ((typeof value) === 'undefined' || ov == value);
    });
  },

  setAttr: function (node, attr, value) {
    if (attr === 'style') {
      value.pairs().forEach(function (kv) {
        node.style[kv[0]] = kv[1];
      });
    } else {
      if (attr === 'class') {
        value = value.join(' ');
      }

      if (attr === 'checked') {
        if (value) {
          value = 'checked';
        } else {
          value = '';
        }

        node.checked = value;
      }

      node.setAttribute(attr, value);
    }
  },

  all: function (node) {
    var arr = [];

    if (!node) {
      return arr;
    }

    if(document !== node) {
      arr.push(node);
    }

    return arr.concat(pw.node.toA(node.getElementsByTagName('*')));
  },

  before: function (node, newNode) {
    node.parentNode.insertBefore(newNode, node);
  },

  after: function (node, newNode) {
    node.parentNode.insertBefore(newNode, this.nextSibling);
  },

  replace: function (node, newNode) {
    node.parentNode.replaceChild(newNode, node);
  },

  append: function (node, newNode) {
    node.appendChild(newNode);
  },

  prepend: function (node, newNode) {
    node.insertBefore(newNode, node.firstChild);
  },

  remove: function (node) {
    node.parentNode.removeChild(node);
  },

  clear: function (node) {
    while (node.firstChild) {
      pw.node.remove(node.firstChild);
    }
  },

  title: function (node, value) {
    var titleNode;
    if (titleNode = node.getElementsByTagName('title')[0]) {
      titleNode.innerText = value;
    }
  },

  toA: function (nodeSet) {
    return Array.prototype.slice.call(nodeSet);
  },

  serialize: function (node) {
    var json = {};
    var working;
    var value;
    var split, last;
    var previous, previous_name;
    node.querySelectorAll('input, select, textarea').forEach(function (input) {
      working = json;
      split = input.name.split('[');
      last = split[split.length - 1];
      split.forEach(function (name) {
        value = pw.node.value(input);

        if (name == ']') {
          if (!(previous[previous_name] instanceof Array)) {
            previous[previous_name] = [];
          }

          if (value) {
            previous[previous_name].push(value);
          }
        }

        if (name != last) {
          value = {};
        }

        name = name.replace(']', '');

        if (name == '' || name == '_method') {
          return;
        }

        if (!working[name]) {
          working[name] = value;
        }

        previous = working;
        previous_name = name;
        working = working[name];
      });
    });

    return json;
  }
};
pw.attrs = {
  init: function (v_or_vs) {
    return new pw_Attrs(pw.collection.init(v_or_vs));
  }
};

var attrTypes = {
  hash: ['style'],
  bool: ['selected', 'checked', 'disabled', 'readonly', 'multiple'],
  mult: ['class']
};

var pw_Attrs = function (collection) {
  this.views = collection.views;
};

pw_Attrs.prototype = {
  findType: function (attr) {
    if (attrTypes.hash.indexOf(attr) > -1) return 'hash';
    if (attrTypes.bool.indexOf(attr) > -1) return 'bool';
    if (attrTypes.mult.indexOf(attr) > -1) return 'mult';
    return 'text';
  },

  findValue: function (view, attr) {
    switch (attr) {
      case 'class':
        return view.node.classList;
      case 'style':
        return view.node.style;
    }

    if (this.findType(attr) === 'bool') {
      return view.node.hasAttribute(attr);
    } else {
      return view.node.getAttribute(attr);
    }
  },

  set: function (attr, value) {
    this.views.forEach(function (view) {
      pw.node.setAttr(view.node, attr, value);
    });
  },

  remove: function (attr) {
    this.views.forEach(function (view) {
      view.node.removeAttribute(attr);
    });
  },

  ensure: function (attr, value) {
    this.views.forEach(function (view) {
      var currentValue = this.findValue(view, attr);

      if (attr === 'class') {
        if (!currentValue.contains(value)) {
          currentValue.add(value);
        }
      } else if (attr === 'style') {
        value.pairs().forEach(function (kv) {
          view.node.style[kv[0]] = kv[1];
        });
      } else if (this.findType(attr) === 'bool') {
        if (!view.node.hasAttribute(attr)) {
          pw.node.setAttr(view.node, attr, attr);
        }
      } else { // just a text attr
        var currentValue = view.node.getAttribute(attr) || '';
        if (!currentValue.match(value)) {
          pw.node.setAttr(view.node, attr, currentValue + value);
        }
      }
    }, this);
  },

  deny: function (attr, value) {
    this.views.forEach(function (view) {
      var currentValue = this.findValue(view, attr);
      if (attr === 'class') {
        if (currentValue.contains(value)) {
          currentValue.remove(value);
        }
      } else if (attr === 'style') {
        value.pairs().forEach(function (kv) {
          view.node.style[kv[0]] = view.node.style[kv[0]].replace(kv[1], '');
        });
      } else if (this.findType(attr) === 'bool') {
        if (view.node.hasAttribute(attr)) {
          view.node.removeAttribute(attr);
        }
      } else { // just a text attr
        pw.node.setAttr(view.node, attr, view.node.getAttribute(attr).replace(value, ''));
      }
    }, this);
  },

  insert: function (attr, value) {
    this.views.forEach(function (view) {
      var currentValue = this.findValue(view, attr);

      switch (attr) {
        case 'class':
          currentValue.add(value);
          break;
        default:
          pw.node.setAttr(view.node, attr, currentValue + value);
          break;
      }
    }, this);
  }
};
/*
  State related functions.
*/

pw.state = {
  build: function (sigArr, parentObj) {
    var nodeState;
    return sigArr.reduce(function (acc, sig) {
      if (nodeState = pw.state.buildForNode(sig, parentObj)) {
        acc.push(nodeState);
      }

      return acc;
    }, []);
  },

  buildForNode: function (sigTuple, parentObj) {
    var sig = sigTuple[0];
    var obj = {};

    if (sig.type === 'scope') {
      obj.id = sig.node.getAttribute('data-id');
      obj.scope = sig.node.getAttribute('data-scope');
    } else if (sig.type === 'prop' && parentObj) {
      parentObj[sig.node.getAttribute('data-prop')] = pw.node.value(sig.node);
      return;
    }

    obj['__nested'] = pw.state.build(sigTuple[1], obj);

    return obj;
  },

  // creates and returns a new pw_State for the document or node
  init: function (node, observer) {
    return new pw_State(node, observer);
  }
};


/*
  pw_State represents the state for a document or node.
*/

var pw_State = function (node) {
  this.node = node;
  //FIXME storing diffs is probably better than full snapshots
  this.snapshots = [];
  this.update();
}

pw_State.prototype = {
  update: function () {
    this.snapshots.push(pw.state.build(pw.node.significant(this.node)));
  },

  // gets the current represented state from the node and diffs it with the current state
  diffNode: function (node) {
    return pw.state.build(pw.node.significant(pw.node.scope(node)))[0];
  },

  revert: function () {
    var initial = pw.util.dup(this.snapshots[0]);
    this.snapshots = [initial];
    return initial;
  },

  rollback: function () {
    this.snapshots.pop();
    return this.current();
  },

  // returns the current state for a node
  node: function (nodeState) {
    return this.current.flatten().find(function (state) {
      return state.scope === nodeState.scope && state.id === nodeState.id;
    });
  },

  append: function (state) {
    var copy = this.copy();
    copy.push(state);
    this.snapshots.push(copy);
  },

  prepend: function (state) {
    var copy = this.copy();
    copy.unshift(state);
    this.snapshots.push(copy);
  },

  delete: function (state) {
    var copy = this.copy();
    var match = copy.find(function (s) {
      return s.id === state.id;
    });

    if (match) {
      copy.splice(copy.indexOf(match), 1);
      this.snapshots.push(copy);
    }
  },

  copy: function () {
    return pw.util.dup(this.current());
  },

  current: function () {
    return this.snapshots[this.snapshots.length - 1];
  },

  initial: function () {
    return this.snapshots[0];
  }
};
/*
  View related functions.
*/

pw.view = {
  // creates and returns a new pw_View for the document or node
  init: function (node) {
    return new pw_View(node);
  },

  fromStr: function (str) {
    var e = document.createElement("div");
    e.innerHTML = str;
    return pw.view.init(e.childNodes[0]);
  }
};

/*
  pw_View contains a document with state. It watches for
  interactions with the document that trigger mutations
  in state. It can also apply state to the view.
*/

var pw_View = function (node) {
  this.node = node;
}

pw_View.prototype = {
  clone: function () {
    return pw.view.init(this.node.cloneNode(true));
  },

  // pakyow api

  title: function (value) {
    pw.node.title(this.node, value);
  },

  text: function (value) {
    this.node.innerText = value;
  },

  html: function (value) {
    this.node.innerHTML = value
  },

  component: function (name) {
    return pw.collection.init(
      pw.node.byAttr(this.node, 'data-ui', name).reduce(function (views, node) {
        return views.concat(pw.view.init(node));
      }, []), this);
  },

  attrs: function () {
    return pw.attrs.init(this);
  },

  with: function (cb) {
    pw.node.with(this.node, cb);
  },

  match: function (data) {
    pw.node.match(this.node, data);
  },

  for: function (data, cb) {
    pw.node.for(this.node, data, cb);
  },

  repeat: function (data, cb) {
    pw.node.repeat(this.node, data, cb);
  },

  bind: function (data, cb) {
    pw.node.bind(data, this.node, cb);
  },

  apply: function (data, cb) {
    pw.node.apply(data, this.node, cb);
  }
};

// pass through lookups
['scope', 'prop'].forEach(function (method) {
  pw_View.prototype[method] = function (name) {
    return pw.collection.init(
      pw.node.byAttr(this.node, 'data-' + method, name).reduce(function (views, node) {
        return views.concat(pw.view.init(node));
      }, []), this, name);
  };
});

// pass through functions without view
['remove', 'clear', 'versionNode'].forEach(function (method) {
  pw_View.prototype[method] = function () {
    return pw.node[method](this.node);
  };
});

// pass through functions with view
['after', 'before', 'replace', 'append', 'prepend', 'insert'].forEach(function (method) {
  pw_View.prototype[method] = function (view) {
    return pw.node[method](this.node, view.node);
  };
});
pw.collection = {
  init: function (view_or_views, parent, scope) {
    if (view_or_views instanceof pw_Collection) {
      return view_or_views
    } else if (view_or_views.constructor !== Array) {
      view_or_views = [view_or_views];
    }

    return new pw_Collection(view_or_views, parent, scope);
  },

  fromNodes: function (nodes, parent, scope) {
    return pw.collection.init(nodes.map(function (node) {
      return pw.view.init(node);
    }), parent, scope);
  }
};

var pw_Collection = function (views, parent, scope) {
  this.views = views;
  this.parent = parent;
  this.scope = scope;
};

pw_Collection.prototype = {
  clone: function () {
    return pw.collection.init(this.views.map(function (view) {
      return view.clone();
    }));
  },

  last: function () {
    return this.views[this.length() - 1];
  },

  first: function () {
    return this.views[0];
  },

  removeView: function(view) {
    var index = this.views.indexOf(view);

    if (index > -1) {
      this.views.splice(index, 1)[0].remove();
    }
  },

  addView: function(view_or_views) {
    var views = [];

    if (view_or_views instanceof pw_Collection) {
      views = view_or_views.views;
    } else {
      views.push(view_or_views);
    }

    if (this.length() > 0) {
      views.forEach(function (view) {
        pw.node.after(this.last().node, view.node);
      }, this);
    } else if (this.parent) {
      views.forEach(function (view) {
        this.parent.append(view);
      }, this);
    }

    this.views = this.views.concat(views);
  },

  order: function (orderedIds) {
    orderedIds.forEach(function (id) {
      if (!id) {
        return;
      }

      var match = this.views.find(function (view) {
        return view.node.getAttribute('data-id') == id.toString();
      });

      if (match) {
        match.node.parentNode.appendChild(match.node);

        // also reorder the list of views
        var i = this.views.indexOf(match);
        this.views.splice(i, 1);
        this.views.push(match);
      }
    }, this);
  },

  length: function () {
    return this.views.length;
  },

  // pakyow api

  attrs: function () {
    return pw.attrs.init(this.views);
  },

  append: function (data) {
    data = Array.ensure(data);

    var last = this.last();
    this.views.push(last.append(data));
    return last;
  },

  prepend: function(data) {
    data = Array.ensure(data);

    var prependedViews = data.map(function (datum) {
      var view = this.first().prepend(datum);
      this.views.push(view);
      return view;
    }, this);

    return pw.collection.init(prependedViews);
  },

  with: function (cb) {
    pw.node.with(this.views, cb);
  },

  for: function(data, fn) {
    data = Array.ensure(data);

    this.views.forEach(function (view, i) {
      fn.call(view, data[i]);
    });
  },

  match: function (data, fn) {
    data = Array.ensure(data);

    if (data.length === 0) {
      this.remove();
      return fn.call(this);
    } else {
      var firstView;
      var firstParent;

      if (this.views[0]) {
        firstView = this.views[0].clone();
        firstParent = this.views[0].node.parentNode;
      }

      this.views.slice(0).forEach(function (view) {
        var id = view.node.getAttribute('data-id');

        if (!id) {
          return;
        }

        if (!data.find(function (datum) { return datum.id.toString() === id })) {
          this.removeView(view);
        }
      }, this);

      if (data.length > this.length()) {
        var self = this;
        this.endpoint.template(this, function (view) {
          if (!view) {
            view = firstView.clone();
            self.parent = pw.view.init(firstParent);
          }

          data.forEach(function (datum) {
            if (!self.views.find(function (view) {
              return view.node.getAttribute('data-id') === (datum.id || '').toString()
            })) {
              var viewToAdd = view.clone();

              if (viewToAdd instanceof pw_Collection) {
                viewToAdd = viewToAdd.views[0];
              }

              viewToAdd.node.setAttribute('data-id', datum.id);
              self.addView(viewToAdd);

              pw.component.findAndInit(viewToAdd.node);
            }
          }, self);

          return fn.call(self);
        });
      } else {
        return fn.call(this);
      }
    }

    return this;
  },

  repeat: function (data, fn) {
    this.match(data, function () {
      this.for(data, fn);
    });
  },

  bind: function (data, fn) {
    this.for(data, function(datum) {
      this.bind(datum);

      if(!(typeof fn === 'undefined')) {
        fn.call(this, datum);
      }
    });

    return this;
  },

  apply: function (data, fn) {
    this.match(data, function () {
      var id;

      this.order(data.map(function (datum) {
        if (id = datum.id) {
          return id.toString();
        }
      }));

      this.bind(data, fn);
    });
  },

  endpoint: function (endpoint) {
    this.endpoint = endpoint;
    return this;
  }
};

// lookup functions
['scope', 'prop', 'component'].forEach(function (method) {
  pw_Collection.prototype[method] = function (name) {
    return pw.collection.init(
      this.views.reduce(function (views, view) {
        return views.concat(view[method](name).views);
      }, [])
    );
  };
});

// pass through functions
['remove', 'clear', 'text', 'html'].forEach(function (method) {
  pw_Collection.prototype[method] = function (arg) {
    this.views.forEach(function (view) {
      view[method](arg);
    });
  };
});
/*
  Component init.
*/

pw.init.register(function () {
  pw.component.findAndInit(document.querySelectorAll('body')[0]);
});

/*
  Component related functions.
*/

// stores component functions by name
var components = {};

// stores component instances by channel
var channelComponents = {};
var channelBroadcasts = {};

// component instances
var componentInstances = {};

pw.component = {
  init: function (view, config) {
    return new pw_Component(view, config);
  },

  resetChannels: function () {
    channelComponents = {};
  },

  findAndInit: function (node) {
    pw.node.byAttr(node, 'data-ui').forEach(function (uiNode) {
      if (uiNode._ui) {
        return;
      }

      var name = uiNode.getAttribute('data-ui');
      var cfn = components[name] || pw.component.init;

      if (!componentInstances[name]) {
        componentInstances[name] = [];
      }

      var channel = uiNode.getAttribute('data-channel');
      var config = uiNode.getAttribute('data-config');
      var view = pw.view.init(uiNode);
      var id = componentInstances[name].length;

      var component = new cfn(view, pw.component.buildConfigObject(config), name, id);
      component.init(view, config, name);

      pw.component.registerForChannel(component, channel);
      componentInstances[name].push(component);

      uiNode._ui = true;
    });
  },

  push: function (packet) {
    var channel = packet.channel;
    var payload = packet.payload;
    var instruct = payload.instruct;

    (channelComponents[channel] || []).forEach(function (component) {
      if (instruct) {
        component.instruct(channel, instruct);
      } else {
        component.message(channel, payload);
      }
    });
  },

  register: function (name, fn) {
    var proto = pw_Component.prototype;

    Object.getOwnPropertyNames(proto).forEach(function (method) {
      fn.prototype[method] = proto[method];
    });

    components[name] = fn;
  },

  buildConfigObject: function(configString) {
    if (!configString) {
      return {};
    }

    return configString.split(';').reduce(function (config, option) {
      var kv = option.trim().split(':');
      config[kv[0].trim()] = kv[1].trim();
      return config;
    }, {});
  },

  registerForChannel: function (component, channel) {
    // store component instance by channel for messaging
    if (!channelComponents[channel]) {
      channelComponents[channel] = [];
    }

    channelComponents[channel].push(component);
  },

  registerForBroadcast: function (channel, cb, component) {
    if (!channelBroadcasts[channel]) {
      channelBroadcasts[channel] = [];
    }

    channelBroadcasts[channel].push([cb, component]);
  },

  deregisterForBroadcast: function (channel, component) {
    var components = channelBroadcasts[channel];

    var instanceTuple = components.find(function (tuple) {
      return tuple[1] == component;
    });

    var i = components.indexOf(instanceTuple);
    components.splice(i, 1);
  },

  broadcast: function (channel, payload) {
    (channelBroadcasts[channel] || []).forEach(function (cbTuple) {
      cbTuple[0].call(cbTuple[1], payload);
    });
  }
};

/*
  pw_Component makes it possible to build custom controls.
*/

var pw_Component = function (view, config, name) {
  // placeholder
};

pw_Component.prototype = {
  init: function (view, config, name) {
    var node = view.node;
    this.view = view;
    this.node = node;
    this.config = config;
    this.name = name;
    this.templates = {};
    var self = this;

    // setup templates
    pw.node.toA(node.querySelectorAll(':scope > *[data-template]')).forEach(function (templateNode) {
      var cloned = templateNode.cloneNode(true);
      pw.node.remove(templateNode);

      var scope = cloned.getAttribute('data-scope');

      if (this.templates[scope]) {
        this.templates[scope].views.push(pw.view.init(cloned));
      } else {
        this.templates[scope] = pw.collection.init(pw.view.init(cloned));
      }

      cloned.removeAttribute('data-template');
    }, this);

    // setup our initial state
    this.state = pw.state.init(this.node);

    // register as a dependent to the parent component
    if (this.dCb) {
      var parentComponent = pw.node.component(this.node.parentNode);

      if (parentComponent) {
        parentComponent.addEventListener('mutated', function (evt) {
          self.transform(self.dCb(evt.target._evtData));
        });

        self.transform(self.dCb(pw.state.init(parentComponent).current()));
      }
    }

    // make it mutable
    var mutableCb = function (evt) {
      evt.preventDefault();

      var scope = pw.node.scope(evt.target);

      if (scope) {
        self.mutated(scope);
      }
    };

    node.addEventListener('submit', mutableCb);
    node.addEventListener('change', function (evt) {
      if (!pw.node.inForm(evt.target)) {
        mutableCb(evt);
      }
    });

    //TODO define other mutable things

    if (this.inited) {
      this.inited();
    }
  },

  listen: function (channel, cb) {
    pw.component.registerForBroadcast(channel, cb, this);
  },

  ignore: function (channel) {
    pw.component.deregisterForBroadcast(channel, this);
  },

  //TODO this is pretty similary to processing instructions
  // for views in that we also have to handle the empty case
  //
  // there might be an opportunity for some refactoring
  instruct: function (channel, instructions) {
    this.endpoint = pw.instruct;

    var current = this.state.current();
    if (current.length === 1) {
      var view = this.view.scope(current[0].scope);
      var node = view.views[0].node;
      if (node.getAttribute('data-version') === 'empty') {
        var self = this;
        pw.instruct.template(view, function (rview) {
          var parent = node.parentNode;
          parent.replaceChild(rview.node, node);

          instructions.forEach(function (instruction) {
            self[instruction[0]](instruction[1]);
          });
        });

        return;
      }
    }

    instructions.forEach(function (instruction) {
      this[instruction[0]](instruction[1]);
    }, this);
  },

  message: function (channel, payload) {
    // placeholder
  },

  mutated: function (node) {
    this.mutation(this.state.diffNode(node));
    this.state.update();

    pw.node.trigger('mutated', this.node, this.state.current());
  },

  mutation: function (mutation) {
    // placeholder
  },

  transform: function (state) {
    this._transform(state);
  },

  _transform: function (state) {
    if (!state) {
      return;
    }

    if (state.length > 0) {
      this.view.scope(state[0].scope).endpoint(this.endpoint || this).apply(state);
    } else {
      pw.node.breadthFirst(this.view.node, function () {
        if (this.hasAttribute('data-scope')) {
          pw.node.remove(this);
        }
      });
    }

    pw.node.trigger('mutated', this.node, this.state.current());
  },

  revert: function () {
    this.transform(this.state.revert());
  },

  rollback: function () {
    this.transform(this.state.rollback());
  },

  template: function (view, cb) {
    var template;

    if (template = this.templates[view.scope]) {
      cb(template);
    }
  },

  delete: function (data) {
    this.state.delete(data);
    this.transform(this.state.current());
  },

  append: function (data) {
    this.state.append(data);
    this.transform(this.state.current());
  },

  prepend: function (data) {
    this.state.prepend(data);
    this.transform(this.state.current());
  },

  parent: function () {
    var parent = pw.node.scope(this.node);

    if (parent) {
      return pw.state.init(parent).current()[0];
    }
  },

  dependent: function (cb) {
    this.dCb = cb;
  }
};
/*
  Socket init.
*/

pw.init.register(function () {
  pw.socket.init({
    cb: function (socket) {
      window.socket = socket;
    }
  });
});

/*
  Socket related functions.
*/

pw.socket = {
  init: function (options) {
    return pw.socket.connect(
      options.host,
      options.port,
      options.protocol,
      options.connId,
      options.cb
    );
  },

  connect: function (host, port, protocol, connId, cb) {
    if(typeof host === 'undefined') host = window.location.hostname;
    if(typeof port === 'undefined') port = window.location.port;
    if(typeof protocol === 'undefined') protocol = window.location.protocol;
    if(typeof connId === 'undefined') connId = document.getElementsByTagName('body')[0].getAttribute('data-socket-connection-id');

    if (!connId) {
      return;
    }

    var wsUrl = '';

    if (protocol === 'http:') {
      wsUrl += 'ws://';
    } else if (protocol === 'https:') {
      wsUrl += 'wss://';
    }

    wsUrl += host;

    if (port) {
      wsUrl += ':' + port;
    }

    wsUrl += '/?socket_connection_id=' + connId;

    return new pw_Socket(wsUrl, cb);
  }
};

var pw_Socket = function (url, cb) {
  var self = this;

  this.callbacks = {};

  this.url = url;
  this.initCb = cb;

  this.ws = new WebSocket(url);

  this.id = url.split('socket_connection_id=')[1];

  var pingInterval;

  this.ws.onmessage = function (evt) {
    pw.component.broadcast('socket:loaded');

    var data = JSON.parse(evt.data);
    if (data.id) {
      var cb = self.callbacks[data.id];
      if (cb) {
        cb.call(this, data);
        return;
      }
    }

    self.message(data);
  };

  this.ws.onclose = function (evt) {
    console.log('socket closed');
    clearInterval(pingInterval);
    self.reconnect();
  };

  this.ws.onopen = function (evt) {
    console.log('socket open');

    if(self.initCb) {
      self.initCb(self);
    }

    pingInterval = setInterval(function () {
      self.send({ action: 'ping' });
    }, 30000);
  }
};

pw_Socket.prototype = {
  send: function (message, cb) {
    pw.component.broadcast('socket:loading');

    message.id = pw.util.guid();
    if (!message.input) {
      message.input = {};
    }
    message.input.socket_connection_id = this.id;
    this.callbacks[message.id] = cb;
    this.ws.send(JSON.stringify(message));
  },

  //TODO handle custom messages (e.g. not pakyow specific)
  message: function (packet) {
    console.log('received message');
    console.log(packet);

    var selector = '*[data-channel="' + packet.channel + '"]';

    if (packet.channel && packet.channel.split(':')[0] === 'component') {
      pw.component.push(packet);
      return;
    }

    var nodes = pw.node.toA(document.querySelectorAll(selector));

    if (nodes.length === 0) {
      //TODO decide how to handle this condition; there are times where this
      // is going to be the case and not an error; at one point we were simply
      // reloading the page, but that doesn't work in all cases
      return;
    }

    pw.instruct.process(pw.collection.fromNodes(nodes, selector), packet, this);
  },

  reconnect: function () {
    var self = this;

    if (!self.wait) {
      self.wait = 100;
    } else {
      self.wait *= 1.25;
    }

    console.log('reconnecting socket in ' + self.wait + 'ms');

    setTimeout(function () {
      pw.socket.init({ cb: self.initCb });
    }, self.wait);
  },

  fetchView: function (lookup, cb) {
    var uri;

    if (window.location.hash) {
      var arr = window.location.hash.split('#:')[1].split('/');
      arr.shift();
      uri = arr.join('/');
    } else {
      uri = window.location.pathname + window.location.search;
    }

    this.send({
      action: 'fetch-view',
      lookup: lookup,
      uri: uri
    }, function (res) {
      var view = pw.view.fromStr(res.body);

      if (view.node) {
        view.node.removeAttribute('data-id');
        cb(view);
      } else {
        cb();
      }
    });
  }
};
pw.instruct = {
  process: function (collection, packet, socket) {
    if (collection.length() === 1 && collection.views[0].node.getAttribute('data-version') === 'empty') {
      pw.instruct.fetchView(packet, socket, collection.views[0].node);
    } else {
      pw.instruct.perform(collection, packet.payload);
    }
  },

  fetchView: function (packet, socket, node) {
    socket.fetchView({ channel: packet.channel }, function (view) {
      if (view) {
        var parent = node.parentNode;
        parent.replaceChild(view.node, node);

        var selector = '*[data-channel="' + packet.channel + '"]';
        var nodes = pw.node.toA(parent.querySelectorAll(selector));
        pw.instruct.perform(pw.collection.fromNodes(nodes, selector), packet.payload);
      } else {
        console.log('trouble fetching view :(');
      }
    });
  },

  // TODO: make this smart and cache results
  template: function (view, cb) {
    var lookup = {};

    if (!view || !view.first()) {
      return cb();
    }

    var node = view.first().node;

    if (node.hasAttribute('data-channel')) {
      lookup.channel = view.first().node.getAttribute('data-channel');
    } else if (node.hasAttribute('data-ui') && node.hasAttribute('data-scope')) {
      lookup.component = pw.node.component(node).getAttribute('data-ui');
      lookup.scope = node.getAttribute('data-scope');
    } else {
      cb();
      return;
    }

    window.socket.fetchView(lookup, function (view) {
      cb(view);
    });
  },

  perform: function (collection, instructions) {
    var self = this;

    (instructions || []).forEach(function (instruction, i) {
      var method = instruction[0];
      var value = instruction[1];
      var nested = instruction[2];

      if (collection[method]) {
        if (method == 'with' || method == 'for' || method == 'bind' || method == 'repeat' || method == 'apply') {
          collection.endpoint(self)[method].call(collection, value, function (datum) {
            pw.instruct.perform(this, nested[value.indexOf(datum)]);
          });
          return;
        } else if (method == 'attrs') {
          self.performAttr(collection.attrs(), nested);
          return;
        } else {
          var mutatedViews = collection[method].call(collection, value);
        }
      } else {
        console.log('could not find method named: ' + method);
        return;
      }

      if (nested instanceof Array) {
        pw.instruct.perform(mutatedViews, nested);
      } else if (mutatedViews) {
        collection = mutatedViews;
      }
    });

    pw.component.findAndInit(collection.node);
  },

  performAttr: function (context, attrInstructions) {
    attrInstructions.forEach(function (attrInstruct) {
      var attr = attrInstruct[0];
      var value = attrInstruct[1];
      var nested = attrInstruct[2];

      if (value) {
        context.set(attr, value);
      } else {
        context[nested[0][0]](attr, nested[0][1]);
      }
    });
  }
};
if (!Array.prototype.flatten) {
  Array.prototype.flatten = function () {
    return this.reduce(function (flat, toFlatten) {
      return flat.concat(Array.isArray(toFlatten) ? toFlatten.flatten() : toFlatten);
    }, []);
  };
}

if (!Array.prototype.find) {
  Array.prototype.find = function(predicate) {
    if (this == null) {
      throw new TypeError('Array.prototype.find called on null or undefined');
    }
    if (typeof predicate !== 'function') {
      throw new TypeError('predicate must be a function');
    }
    var list = Object(this);
    var length = list.length >>> 0;
    var thisArg = arguments[1];
    var value;

    for (var i = 0; i < length; i++) {
      value = list[i];
      if (predicate.call(thisArg, value, i, list)) {
        return value;
      }
    }
    return undefined;
  };
}

Array.ensure = function (value) {
  if(!(value instanceof Array)) {
    return [value];
  }

  return value
}

NodeList.prototype.forEach = Array.prototype.forEach;
if (!Object.prototype.pairs) {
  Object.defineProperty(Object.prototype, "pairs", {
    value: function() {
      return Object.keys(this).map(function (key) {
        return [key, this[key]];
      }, this);
    },
    enumerable: false
  });
}

  if (typeof define === "function" && define.amd) {
    define(pw);
  } else if (typeof module === "object" && module.exports) {
    module.exports = pw;
  } else {
    this.pw = pw;
  }
})();
