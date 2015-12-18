# 0.10.3

  * Fixes several bugs related to nested partials
  * Reprocess view contents with html processor
  * Fixes a bug causing partials not to be duped

# 0.10.0 / 2015-10-19

  * Adds precomposition to composer
  * Fixes binding action for nested resources
  * Fixes variable name in remap_partials
  * Setup form on `_root` rather than `action` prop
  * Handles view paths that don't define an `index` view
  * Adds `ViewCollection#scoped_as` convenience method
  * Renames default template to `default` (instead of `pakyow`)
  * Adds convenience method to check for view existence
  * Support binding hashes with `String` keys
  * Fixes a bug when a node is inserted after another node that also has a sibling
  * Fixes binding to props nested in partial
  * Now allows views for a view store to be fragmented across multiple directories
  * Adds versioned scopes with auto empty handling
  * Now sets scope name explicitly for `ViewCollection` built from a `View`
  * Adds a helper method for checking if a attribute exists
  * Adds support for components and channels (realtime ftw)
  * Adds id of object to scoped node during binding
  * Fixes a bug with view contexts in presenter helpers
  * Ported all tests to rspec
  * Fixes a bug finding scopes in a nested partial
  * Fixes a bug where unused partials still being included as parts in the composer
  * Fixes a `StringDoc` bug when structure is empty
  * Fixes bug preventing passed binding functions from being used when no binding sets are registered for scope
  * Fixes namespace collisions
  * Fixes error when matching data empty collection
  * Renames `inner_html` to `html`
  * Now only reloads a view store if the contents have changed
  * Yields `prop` node rather than full `scope` in bindings
  * Handles `AttributesCollection#<<` for all use cases
  * Adds `to_html` method on composer
  * No longer complains about a view store missing a template directory
  * Now finds view info for a path that doesn't contain a page
  * Allows root nodes to be appendable in string doc
  * Removes nokogiri doc

# 0.9.1 / 2014-12-06

  * Fixes bug where name attribute wasn't set on form fields when binding without a value
  * Fixes bug causing all partials (not just available ones) to be defined as view parts
  * Fixes bug causing form action binding to break

# 0.9.0 / 2014-11-09

  * Introduces StringDoc, replacing Nokogiri for view rendering with a performant alternative
  * Adds the ability to set an empty first option in bindings
  * Remove the annoying "no content" for container log message
  * Binding context must now be explicitly passed when binding
  * Yield bindable value before bindable in view binding fns
  * Fixes bug causing non-html view contents to be processed twice
  * Removes support for Ruby versions < 2.0.0

# 0.8.0 / 2014-03-02

  * Major rewrite, including new view syntax, composer, and transformation api

# 0.7.2 / 2012-02-29

  * No changes -- bumped version to be consistent

# 0.7.1 / 2012-01-08

  * View caching fixes
  * Changed binder to allow definition for multiple endpoints
  * Changed in_context to accept context as block argument
  * Changed action binder to add leading slash if needed
  * Change to allow a view's content to be set to nil
  * Fixed Views#find method

# 0.7.0 / 2011-11-19

  * Cleaned up core/presenter interface
  * Optimized view caching
  * Binding occurs on the label an object is being bound to, not the object type
  * Root view override in index directories no longer specify a root view for siblings
  * Fixed problem binding to a checkbox who’s value attribute is not set

# 0.6.3 / 2011-09-13

  * Fixes binding to bindings defined by HTML 'name' attribute

# 0.6.2 / 2011-08-20

  * Fixes issue binding object to root nodes
  * JRuby Support

# 0.6.1 / 2011-08-20

  * Fixes gemspec problem

# 0.6.0 / 2011-08-20

 * Initial gem release of 0.6.0 codebase
