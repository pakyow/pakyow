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
      expect(run_command(command, help: true, project: true, cleanup: false)).to eq("\e[34;1mShow defined sources for an app\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow info:sources\n\n\e[1mOPTIONS\e[0m\n  -a, --app=app  \e[33mThe app to run the command on\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "shows sources info" do
      expect(run_command(command, project: true, cleanup: false)).to eq("\e[1m:comments\e[0m \e[34mpakyow/framework\e[0m\n  belongs_to :post\n\n  attribute :body, :string\n  attribute :created_at, :datetime\n  attribute :id, :bignum\n  attribute :post_id, :bignum\n  attribute :updated_at, :datetime\n\n\e[1m:posts\e[0m /posts.rb:23\n  has_many :comments\n\n  attribute :body, :string\n  attribute :created_at, :datetime\n  attribute :id, :bignum\n  attribute :title, :string\n  attribute :updated_at, :datetime\n\n")
    end

    it "needs more specific tests"
  end
end
