require "pakyow/runnable/formation"

RSpec.describe "parsing a formation with multiple top-level containers" do
  it "raises Pakyow::FormationError" do
    expect {
      Pakyow::Runnable::Formation.parse("foo.bar=1,bar.baz=1")
    }.to raise_error(Pakyow::FormationError, "`foo.bar=1,bar.baz=1' is an invalid formation because it defines multiple top-level containers ([:foo, :bar])")
  end
end
