require "pakyow/app/connection/session/cookie"

RSpec.describe Pakyow::App::Connection::Session::Cookie do
  describe "#initialize" do
    it "initializes with a connection and options"
    it "invokes super with connection, options, and the deserialized session"
    it "sets the session cookie with the configured name"
    it "sets the request cookie value to the session object"

    describe "session cookie" do
      it "sets the configured domain value"
      it "sets the configured path value"
      it "sets the configured max_age value"
      it "sets the configured expires value"
      it "sets the configured secure value"
      it "sets the configured http_only value"
      it "sets the configured same_site value"
      it "sets the deserialized value"
    end

    context "cookie has already been deserialized" do
      it "initializes"
      it "does not change the cookie"
    end

    context "cookie cannot be deserialized" do
      it "resets the session"
    end
  end

  describe "#to_s" do
    it "dumps the hash representation of the session"
  end
end
