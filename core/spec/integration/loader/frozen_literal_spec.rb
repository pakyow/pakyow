require_relative "shared"

RSpec.describe "loading code with a frozen string literal comment" do
  include_context "loader"

  let(:loader_path) {
    File.expand_path("../support/frozen_literal/simple.rb", __FILE__)
  }

  it "respects the literal" do
    expect(target.state(:foo).const_get("FOO").frozen?).to be(true)
  end
end
