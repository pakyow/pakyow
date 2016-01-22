require "spec_helper"

RSpec.shared_examples "help information" do |command|
  it "prints help information" do
    output = `#{command}`

    expect(output).to match(/Usage|Commands/)
  end
end

RSpec.describe "command line interface" do
  describe "help" do
    it_behaves_like "help information", "bin/pakyow --help"
    it_behaves_like "help information", "bin/pakyow -h"

    %w(console new server version).each do |command|
      describe "#{command} help" do
        it_behaves_like "help information", "bin/pakyow help #{command}"
      end
    end
  end

  describe "version" do
    it "outputs current Pakyow version" do
      output = `bin/pakyow version`.chomp

      expect(output).to eq("Pakyow #{Pakyow::VERSION}")
    end

    it "is aliased as --version and -v" do
      expect(`bin/pakyow --version`.chomp).to eq("Pakyow #{Pakyow::VERSION}")
      expect(`bin/pakyow -v`.chomp).to eq("Pakyow #{Pakyow::VERSION}")
    end
  end
end
