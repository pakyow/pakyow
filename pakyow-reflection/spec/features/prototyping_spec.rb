RSpec.describe "reflection in prototype mode" do
  include_context "app"

  let :mode do
    :prototype
  end

  it "does not create the mirror" do
    expect(Pakyow.app(:test).mirror).to be(nil)
  end
end
