RSpec.describe Pakyow::ProcessManager do
  before do
    allow(Process::Group).to receive(:new).and_return(process_group)
    allow(Pakyow).to receive(:logger).and_return(logger)
  end

  after do
    instance.stop
  end

  let(:logger) {
    double(:logger, houston: nil)
  }

  let(:process_group) {
    Process::Group.new
  }

  let(:instance) {
    described_class.new
  }

  let(:process) {
    {
      name: process_name,
      block: process_block,
      count: process_count,
      restartable: process_is_restartable
    }
  }

  let(:process_name) {
    "test process"
  }

  let(:process_block) {
    -> { sleep }
  }

  let(:process_count) {
    1
  }

  let(:process_is_restartable) {
    true
  }

  describe "#add" do
    context "process fails to start" do
      let(:process_block) {
        -> { fail }
      }

      it "only tries to start the process once" do
        expect(process_group).to receive(:fork).once.and_call_original
        instance.add(process)
        instance.wait
      end
    end
  end
end
