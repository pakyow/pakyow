RSpec.describe Pakyow::Connection do
  describe "#initialize" do
    it "initializes with an app, request, and response"
  end

  describe "#processed?" do
    it "defaults to false"
  end

  describe "#processed" do
    it "marks the state as processed"
  end

  describe "#response=" do
    it "replaces the response"
  end

  describe "#set" do
    it "sets a value by key"
  end

  describe "#get" do
    it "gets a value by key"
  end

  describe "#set_cookies" do
    it "ignores cookies that already exist with the value"
    it "sets cookies that already exist, but not with the given value"
    it "sets cookies that do not already exist"
    it "deletes cookies with nil values"
    it "deletes cookies deleted from the request"

    describe "the cookie" do
      it "includes the configured cookie path"
      it "includes the configured cookie expiration"
    end
  end
end
