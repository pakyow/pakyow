require "fileutils"
require "securerandom"

RSpec.describe "setting the environment config in the cli" do
  before do
    FileUtils.mkdir_p(path)
    config_file.open("w+") do |file|
      file.write <<~CODE
        ENV[#{key.inspect}] = "true"
      CODE
    end

    Pakyow.command :config do; end
    allow(output).to receive(:tty?).and_return(true)
    allow(Pakyow).to receive(:project?).and_return(true)
  end

  after do
    FileUtils.rm_r(path)
  end

  let(:command) {
    "config"
  }

  let(:argv) {
    ["--config=#{config_path}"]
  }

  let(:output) {
    StringIO.new
  }

  let(:result) {
    output.rewind; output.read
  }

  let(:config_path) {
    path.join("e")
  }

  let(:config_file) {
    Pathname.new(config_path.to_s + ".rb")
  }

  let(:path) {
    Pathname.new(File.expand_path("../tmp", __FILE__))
  }

  let(:key) {
    SecureRandom.hex(8).upcase
  }

  it "loads the correct environment config" do
    expect {
      Pakyow::CLI.run([command].concat(argv).compact, output: output)
    }.to change {
      ENV[key]
    }.from(nil).to("true")
  end
end
