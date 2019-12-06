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
    Pakyow::Process.new(
      name: process_name,
      count: process_count,
      restartable: process_is_restartable,
      &process_block
    )
  }

  let(:process_name) {
    "test process"
  }

  let(:process_block) {
    -> {}
  }

  let(:process_count) {
    1
  }

  let(:process_is_restartable) {
    true
  }

  describe "#add" do
    it "starts the expected number of processes" do
      expect(process_group).to receive(:fork).once.and_call_original
      instance.add(process)
      instance.stop
      instance.wait
    end

    context "running multiple process instances" do
      let(:process_count) {
        3
      }

      it "starts the expected number of processes" do
        expect(process_group).to receive(:fork).thrice.and_call_original
        instance.add(process)
        instance.stop
        instance.wait
      end
    end

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

    describe "backwards compatibility with old hash style processes" do
      before do
        allow(instance).to receive(:run)
        allow(Pakyow).to receive(:deprecated)
      end

      let(:instance) {
        described_class.new
      }

      let(:process) {
        {
          name: process_name,
          block: process_block,
          count: process_count,
          restartable: process_is_restartable,
        }
      }

      let(:process_name) {
        "test"
      }

      let(:process_block) {
        Proc.new do
          "called"
        end
      }

      let(:process_count) {
        42
      }

      let(:process_is_restartable) {
        true
      }

      it "is deprecated" do
        expect(Pakyow).to receive(:deprecated).with(
          "passing a `Hash' to `Pakyow::ProcessManager#add'",
          solution: "pass a `Pakyow::Process' instance"
        )

        instance.add(process)
      end

      it "builds and runs a Process instance" do
        expect(instance).to receive(:run) do |process_to_run|
          expect(process_to_run.name).to eq(process_name)
          expect(process_to_run.count).to eq(process_count)
          expect(process_to_run.restartable?).to eq(process_is_restartable)
          expect(process_to_run.call).to eq("called")
        end

        instance.add(process)
      end
    end
  end
end
