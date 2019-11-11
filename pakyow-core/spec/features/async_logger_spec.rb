RSpec.describe "the async logger" do
  include_context "app"

  it "is of the expected type" do
    expect(Console.logger.type).to eq("asnc")
  end

  it "outputs to the global logger" do
    expect(Console.logger.output).to be(Pakyow.global_logger)
  end

  it "logs messages at the warn level" do
    expect(Console.logger.level).to be(3)
  end
end
