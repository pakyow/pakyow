# TODO: session / verifier are app-level concerns, not environment level concerns; this means that
# we can't setup a session or initialize a verifier until the connection has additional context made
# available after a connection is mapped to a specific app; perhaps in an `app=` method?
#
# after thinking about this we need a new connection object that wraps a connection, then passed to
# the app; this object is the one that'll have verifier, values, session, and other app concerns
# it can also be isolated, because we'll have the option of pulling from the app object
#
# what do we call it?
# AppConnection, RoutedConnection, WrappedConnection, App::Connection (ding ding ding)
# just create it in App#call, where the original connection is passed
#
RSpec.shared_examples :connection_verifier do
  it "needs specs (waiting on session)"
end
