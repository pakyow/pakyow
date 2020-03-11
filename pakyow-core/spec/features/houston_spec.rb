RSpec.describe "reporting errors through the environment" do
  include_context "app"

  before do
    allow(Pakyow.logger).to receive(:houston)

    Pakyow.on :error, exec: false do |error|
      @before_error = error
    end

    Pakyow.after :error, exec: false do |error|
      @after_error = error
    end
  end

  let(:error) {
    RuntimeError.new
  }

  it "logs the error" do
    expect(Pakyow.logger).to receive(:houston).with(error)

    Pakyow.houston(error)
  end

  it "calls before error hooks" do
    Pakyow.houston(error)

    expect(@before_error).to be(error)
  end

  it "calls after error hooks" do
    Pakyow.houston(error)

    expect(@after_error).to be(error)
  end

  context "hook errors" do
    before do
      Pakyow.on :error do
        fail "reporting failed"
      end
    end

    it "raises the error" do
      expect {
        Pakyow.houston(error)
      }.to raise_error do |error|
        expect(error.message).to eq("reporting failed")
      end
    end

    it "still logs the underlying error" do
      expect(Pakyow.logger).to receive(:houston).with(error)

      begin
        Pakyow.houston(error)
      rescue
      end
    end
  end
end
