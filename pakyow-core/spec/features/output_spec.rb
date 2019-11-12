RSpec.describe "the environment output" do
  context "before setup" do
    it "builds a human formatter" do
      expect(Pakyow.output).to be_instance_of(Pakyow::Logger::Formatters::Human)
    end

    it "includes stdout as a destination" do
      destination = Pakyow.output.output
      expect(destination.name).to eq(:stdout)
      expect(destination.io).to be($stdout)
    end
  end

  context "after setup" do
    before do
      Pakyow.config.logger.formatter = Pakyow::Logger::Formatters::Logfmt
      Pakyow.config.logger.destinations = { io1: io1, io2: io2, io3: io3 }

      # Build the default logger.
      #
      Pakyow.output
    end

    include_context "app"

    let(:io1) {
      StringIO.new
    }

    let(:io2) {
      StringIO.new
    }

    let(:io3) {
      StringIO.new
    }

    it "builds a formatter of the configured type" do
      expect(Pakyow.output).to be_instance_of(Pakyow::Logger::Formatters::Logfmt)
    end

    it "includes all configured destinations" do
      destinations = Pakyow.output.output.destinations
      expect(destinations[0].name).to eq(:io1)
      expect(destinations[0].io).to be(io1)
      expect(destinations[1].name).to eq(:io2)
      expect(destinations[1].io).to be(io2)
      expect(destinations[2].name).to eq(:io3)
      expect(destinations[2].io).to be(io3)
    end

    describe "setting the sync mode on destinations" do
      context "config.logger.sync is true" do
        it "sets the sync mode to true"
      end

      context "config.logger.sync is false" do
        it "sets the sync mode to false"
      end
    end
  end
end
