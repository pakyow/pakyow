RSpec.describe "booting the environment when running the cli" do
  before do
    local = self
    Pakyow.command :foo do
      action do
        local.booted = Pakyow.booted?
      end
    end
  end

  attr_accessor :booted, :loaded

  def run(*command)
    output = StringIO.new
    allow(output).to receive(:tty?).and_return(true)
    allow(Pakyow::CLI).to receive(:project_context?).and_return(true)
    Pakyow::CLI.run(command, output: output)
  end

  it "boots by default" do
    run "foo"

    expect(@booted).to be(true)
  end

  context "command manages the boot process" do
    before do
      local = self
      Pakyow.command :bar, boot: false do
        action do
          local.booted = Pakyow.booted?
          local.loaded = Pakyow.loaded?
        end
      end
    end

    it "does not boot at the time of running the command" do
      run "bar"

      expect(@booted).to be(false)
    end

    it "does not load at the time of running the command" do
      run "bar"

      expect(@loaded).to be(false)
    end
  end
end
