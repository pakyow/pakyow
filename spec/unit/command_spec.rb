require "pakyow/cli"

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
      expect(Pakyow::CLI).to receive(:new)
      run_command
    end
  end

  context "without bundler" do
    before do
      @bundler = Object.const_get(:Bundler)
      Object.send(:remove_const, :Bundler)
    end

    after do
      Object.const_set(:Bundler, @bundler)
    end

    context "pakyow binstub exists" do
      before do
        expect(File).to receive(:exist?).with(
          File.join(File.expand_path("../../../", __FILE__), "bin/pakyow")
        ).and_return(true)
      end

      it "runs the binstub with the same arguments" do
        expect_any_instance_of(Object).to receive(:exec).with(
          "#{File.join(File.expand_path("../../../", __FILE__), "bin/pakyow")} #{ARGV.join(" ")}"
        )

        run_command
      end

      it "does not start the cli" do
        expect(Pakyow::CLI).to_not receive(:new)
        run_command
      end
    end

    context "pakyow binstub does not exist" do
      before do
        expect(File).to receive(:exist?).with(
          File.join(File.expand_path("../../../", __FILE__), "bin/pakyow")
        ).and_return(false)
      end

      it "starts the cli" do
        expect(Pakyow::CLI).to receive(:new)
        run_command
      end
    end
  end
end
