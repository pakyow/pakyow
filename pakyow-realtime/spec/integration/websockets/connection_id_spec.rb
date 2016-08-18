require "integration/support/int_helper"

describe "mixing in the connection id" do
  context "when the response has a body tag" do
    it "mixes in the connection id into the body"
  end
  
  context "when the response does not have a body tag" do
    it "does nothing"
  end
end
