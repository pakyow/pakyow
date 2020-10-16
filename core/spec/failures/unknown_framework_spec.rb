RSpec.describe "loading an unknown framework" do
  it "raises an unknown framework error" do
    expect {
      Pakyow.app(:test, only: [:foo])
    }.to raise_error(Pakyow::UnknownFramework) do |error|
      expect(error.to_s).to eq("`foo' is not a known framework")
    end
  end
end
