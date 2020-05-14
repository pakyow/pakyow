RSpec.describe "running a container with an unknown strategy" do
  include_context "app"

  it "raises Pakyow::UnknownContainerStrategy" do
    expect {
      Pakyow.container(:supervisor).run(strategy: "foo")
    }.to raise_error(Pakyow::UnknownContainerStrategy, "`foo' is not a known container strategy")
  end
end
