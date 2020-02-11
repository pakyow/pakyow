require "pakyow/cli"
require "pakyow/support/system"

RSpec.describe "pakyow command" do
  def run_command
    eval(File.read(File.expand_path("../../../commands/pakyow", __FILE__)))
  end

  before do
    allow_any_instance_of(Object).to receive(:exec)
  end

  context "with bundler" do
    before do
      expect(defined?(Bundler)).to eq("constant")
    end

    it "starts the cli" do
      expect(Pakyow::CLI).to receive(:run)
      run_command
    end
  end

  context "without bundler" do
    before do
      hide_const("Bundler")
      allow(Pakyow::CLI).to receive(:run)
    end

    context "gemfile exists" do
      before do
        allow(self).to receive(:require).with("pakyow/support/system")
        allow(self).to receive(:require).with("pakyow/cli")
        allow(self).to receive(:require).with("bundler/setup")

        allow(Pakyow::Support::System).to receive(:gemfile?).and_return(true)
      end

      it "sets up bundler" do
        expect(self).to receive(:require).with("bundler/setup")
        run_command
      end

      it "starts the cli" do
        expect(Pakyow::CLI).to receive(:run)
        run_command
      end

      context "bundler isn't available" do
        before do
          allow(self).to receive(:require).with("bundler/setup").and_raise(LoadError)
        end

        it "does not error" do
          expect {
            run_command
          }.not_to raise_error
          run_command
        end

        it "starts the cli" do
          expect(Pakyow::CLI).to receive(:run)
          run_command
        end
      end
    end

    context "gemfile does not exist" do
      before do
        allow(Pakyow::Support::System).to receive(:gemfile?).and_return(false)
      end

      it "does not setup bundler" do
        expect(self).not_to receive(:require).with("bundler/setup")
        run_command
      end

      it "starts the cli" do
        expect(Pakyow::CLI).to receive(:run)
        run_command
      end
    end
  end
end
