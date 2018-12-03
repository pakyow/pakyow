RSpec.describe "querying an ephemeral data source" do
  include_context "testable app"

  let :data do
    Pakyow.apps.first.data
  end

  before do
    @data = data.ephemeral(:test).set(
      [
        { value: 1 },
        { value: 2 },
        { value: 3 }
      ]
    )
  end

  it "returns an array" do
    expect(
      @data.to_a.map { |result| result[:value] }
    ).to eq([1, 2, 3])
  end

  it "returns one" do
    expect(
      @data.one[:value]
    ).to eq(1)
  end
end
