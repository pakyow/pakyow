# 0.11.3

  * Fixes a bug serializing Rack::Session as a hash
  * Prevent nils from being returned in mutable data

# 0.11.0

  * Mutators are now evaluated in a proper app context
  * Helper methods can now be called inside of a mutator
  * Sessions are now stored with mutations and available when the mutation is invoked after a state change
  * Registered mutations are now unregistered when the WebSocket shuts down
  * Qualification values are now typecasted to strings before comparison
  * Removes code that inserts a node when subscribing an empty view
  * Automatically returns the mutated view from the mutation
  * Adds support for view versioning
  * Allows mutables and mutations to have different scopes
  * Moves everything into the Pakyow namespace
  * Now sets `pakyow.socket` on request env when fetching view
  * Fixes a bug determining qualifiers with non-array data
  * No longer registers mutations registered on a socket request

# 0.10.0 / 2015-10-19

  * Initial release
