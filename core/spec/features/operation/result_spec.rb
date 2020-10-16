RSpec.describe "exposing results from an operation" do
  include_context "app"

  let(:app_def) {
    Proc.new {
      operation :foo do
        action do |value|
          value
        end
      end
    }
  }

  let(:operation) {
    app.operations(:foo).new
  }

  it "exposes the result" do
    expect(operation.perform(:foo).result).to eq(:foo)
  end

  context "operation has not performed" do
    it "returns nil" do
      expect(operation.result).to be(nil)
    end
  end

  context "operation is performed multiple times" do
    it "exposes the latest result" do
      expect(operation.perform(:foo).result).to eq(:foo)
      expect(operation.perform(:bar).result).to eq(:bar)
    end
  end

  describe "multithread support" do
    it "exposes the latest result to a child thread" do
      result = nil
      operation.perform(:foo)
      Thread.new { result = operation.result }.join
      expect(result).to eq(:foo)
    end

    context "child thread performs" do
      it "exposes the result to the child thread" do
        result = nil
        Thread.new { result = operation.perform(:foo).result }.join
        expect(result).to eq(:foo)
      end

      it "exposes the result to the parent thread" do
        Thread.new { operation.perform(:foo) }.join
        expect(operation.result).to eq(:foo)
      end

      it "does not change an existing result in the parent thread" do
        operation.perform(:foo)
        Thread.new { operation.perform(:bar) }.join
        expect(operation.result).to eq(:foo)
      end
    end
  end
end
