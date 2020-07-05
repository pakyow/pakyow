RSpec.describe "debugging a cli failure" do
  before do
    Pakyow.command :failed do
      action do
        raise RuntimeError, "something went wrong"
      end
    end

    allow(Pakyow).to receive(:project?).and_return(true)
  end

  let(:command) {
    "failed"
  }

  let(:argv) {
    ["--debug"]
  }

  let(:output) {
    output = StringIO.new
    allow(output).to receive(:tty?).and_return(true)
    Pakyow::CLI.run([command].concat(argv).compact, output: output)
    output.rewind; output.read
  }

  it "prints the expected output" do
    cached_expectation "cli/debug" do
      output
    end
  end
end
