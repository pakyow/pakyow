RSpec.describe "using multiple handleable objects" do
  let(:handleable_1) {
    Class.new do
      include Pakyow::Support::Handleable
    end
  }

  let(:handleable_2) {
    Class.new do
      include Pakyow::Support::Handleable
    end
  }

  attr_accessor :handled

  after do
    @handled.clear
  end

  context "event is not an exception" do
    before do
      local = self

      handleable_1.handle :foo do
        local.handled << :foo_1
      end

      handleable_2.handle :foo do
        local.handled << :foo_2
      end

      @handled = []
    end

    it "calls handlers in both contexts" do
      handleable_2.trigger :foo do
        handleable_1.trigger :foo
      end

      expect(handled).to eq([:foo_2, :foo_1])
    end
  end

  context "event is an exception" do
    before do
      local = self

      handleable_1.handle RuntimeError do
        local.handled << :foo_1
      end

      handleable_2.handle RuntimeError do
        local.handled << :foo_2
      end

      @handled = []
    end

    it "calls handlers in both contexts" do
      error = RuntimeError.new

      handleable_2.trigger error do
        handleable_1.trigger error
      end

      expect(handled).to eq([:foo_2, :foo_1])
    end

    it "re-raises the error when no handlers match" do
      error = ArgumentError.new

      expect {
        handleable_2.trigger error do
          handleable_1.trigger error
        end
      }.to raise_error(error)
    end
  end
end
