require "pakyow/cli"

RSpec.describe "cli: info:sources" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"
  include_context "command"

  let(:app_def) {
    Proc.new {
      source :posts do
        def self.source_location
          ["/posts.rb", 23]
        end

        has_many :comments

        attribute :title
        attribute :body
      end

      source :comments do
        def self.source_location
          [
            File.join(
              Pakyow::Support::System.local_framework_path_string,
              "pakyow-framework/comments.rb"
            ), 1
          ]
        end

        attribute :body
      end
    }
  }

  let :command do
    "info:sources"
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/info/sources/help" do
        run_command(command, help: true, project: true, cleanup: false)
      end
    end
  end

  describe "running" do
    it "shows sources info" do
      cached_expectation "commands/info/sources/default" do
        run_command(command, project: true, cleanup: false)
      end
    end

    it "needs more specific tests"
  end
end
