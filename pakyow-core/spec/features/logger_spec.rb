RSpec.describe "the environment logger" do
  context "before setup" do
    it "is a default logger" do
      expect(Pakyow.logger.type).to eq("dflt")
    end

    it "outputs to the global logger" do
      expect(Pakyow.logger.output).to be(Pakyow.global_logger)
    end

    it "logs all messages" do
      expect(Pakyow.logger.level).to eq(0)
    end
  end

  context "after setup" do
    before do
      # Build the default logger.
      #
      Pakyow.logger
    end

    include_context "app"

    it "is a thread local logger" do
      expect(Pakyow.logger).to be_instance_of(Pakyow::Logger::ThreadLocal)
    end

    it "is of the expected type" do
      expect(Pakyow.logger.target.type).to eq("pkyw")
    end

    it "outputs to the new global logger" do
      expect(Pakyow.logger.target.output).to be(Pakyow.global_logger)
    end

    it "logs messages of the configured level" do
      expect(Pakyow.logger.target.level).to eq(7)
    end
  end

  describe "holding a reference to the thread local before setup" do
    before do
      @logger = Pakyow.logger
    end

    include_context "app"

    context "after setup" do
      it "uses the configured logger" do
        expect(@logger.target).to receive(:warn).with("foo")
        Pakyow.logger.warn "foo"
      end
    end
  end
end
