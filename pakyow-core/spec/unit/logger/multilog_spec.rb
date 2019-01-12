RSpec.describe Pakyow::Logger::MultiLog do
  describe "initialization" do
    context "target is a string" do
      let :multilog do
        Pakyow::Logger::MultiLog.new("/dev/null")
      end

      it "opens a file" do
        expect(multilog.targets[0]).to be_instance_of(File)
        expect(multilog.targets[0].path).to eq("/dev/null")
      end
    end
  end

  context "with a single target" do
    let :target do
      double
    end

    let :multilog do
      Pakyow::Logger::MultiLog.new(target)
    end

    it "initializes" do
      expect(multilog.targets).to include(target)
    end

    it "writes" do
      expect(target).to receive(:write).with("foo")
      multilog.write("foo")
    end

    it "closes" do
      expect(target).to receive(:close)
      multilog.close
    end

    it "flushes" do
      expect(target).to receive(:flush)
      multilog.flush
    end
  end

  context "with multiple targets" do
    let :targets do
      [double, double]
    end

    let :multilog do
      Pakyow::Logger::MultiLog.new(*targets)
    end

    it "initializes" do
      expect(multilog.targets).to include(targets[0])
      expect(multilog.targets).to include(targets[1])
    end

    it "writes to each" do
      expect(targets[0]).to receive(:write).with("foo")
      expect(targets[1]).to receive(:write).with("foo")
      multilog.write("foo")
    end

    it "closes each" do
      expect(targets[0]).to receive(:close)
      expect(targets[1]).to receive(:close)
      multilog.close
    end

    it "flushes each" do
      expect(targets[0]).to receive(:flush)
      expect(targets[1]).to receive(:flush)
      multilog.flush
    end
  end
end
