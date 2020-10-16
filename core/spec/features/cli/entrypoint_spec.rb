require "pakyow/cli"

RSpec.describe "the cli entrypoint" do
  describe "handling interrupts" do
    before do
      expect(Pakyow::CLI).to receive(:run).and_raise(Interrupt)
    end

    it "does not expose the interrupt" do
      expect {
        load File.expand_path("../../../../commands/pakyow", __FILE__)
      }.not_to raise_error
    end
  end
end
