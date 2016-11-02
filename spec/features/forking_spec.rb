RSpec.describe "forking the environment" do
  it "succeeds" do
    Pakyow.fork do
      @called = true
    end

    expect(@called).to be(true)
  end

  context "when a before hook is registered" do
    before do
      Pakyow.before :fork do |env|
        @called = true
      end
    end

    it "calls the hook" do
      Pakyow.fork do; end
      expect(@called).to be(true)
    end
  end

  context "when an after hook is registered" do
    before do
      Pakyow.after :fork do |env|
        @called = true
      end
    end

    it "calls the hook" do
      Pakyow.fork do; end
      expect(@called).to be(true)
    end
  end
end
