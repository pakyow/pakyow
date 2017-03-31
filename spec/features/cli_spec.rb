RSpec.shared_examples "help information" do |command|
  it "prints help information" do
    output = `#{command}`

    expect(output).to match(/Usage|Commands/)
  end
end

RSpec.describe "command line interface" do
  describe "help" do
    it_behaves_like "help information", "commands/pakyow --help"
    it_behaves_like "help information", "commands/pakyow -h"

    %w(console new server version).each do |command|
      describe "#{command} help" do
        it_behaves_like "help information", "commands/pakyow help #{command}"
      end
    end
  end

  describe "console" do
    context "current directory is not a pakyow app" do
      it "kindly notifies the user" do
        output = `commands/pakyow console 2>&1`.chomp

        expect(output).to match("must run.*console")
      end
    end
  end

  # TODO: we need to find a better way to detect that
  # we're running within a pakyow directory
  xdescribe "server" do
    context "current directory is not a pakyow app" do
      it "kindly notifies the user" do
        output = `commands/pakyow server 2>&1`.chomp

        expect(output).to match("must run.*server")
      end
    end
  end

  describe "version" do
    it "outputs current Pakyow version" do
      output = `commands/pakyow version`.chomp

      expect(output).to eq("Pakyow v#{Pakyow::VERSION}")
    end

    it "is aliased as --version and -v" do
      expect(`commands/pakyow --version`.chomp).to eq("Pakyow v#{Pakyow::VERSION}")
      expect(`commands/pakyow -v`.chomp).to eq("Pakyow v#{Pakyow::VERSION}")
    end
  end
end
