require "spec_helper"

RSpec.shared_examples "help information" do |command:|
  it "prints help information" do
    output = `#{command}`

    expect(output).to include("Usage")
  end
end

RSpec.describe "command line interface" do
  describe "help" do
    it_behaves_like "help information", command: "bin/pakyow --help"
    it_behaves_like "help information", command: "bin/pakyow -h"

    %w(console new server).each do |command|
      describe "#{command} help" do
        it_behaves_like "help information", command: "bin/pakyow #{command} --help"
      end
    end
  end
end
