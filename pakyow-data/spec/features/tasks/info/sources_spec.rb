require "pakyow/cli"
require_relative "../../../../../spec/context/command_context"
require_relative "../../../../../spec/helpers/command_helpers"
require_relative "../../../../../spec/helpers/output_helpers"

RSpec.describe "cli: info:sources" do
  include_context "command"
  include CommandHelpers
  include OutputHelpers

  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end

    Pakyow.app :test do
      source :posts do
        self.__source_location = ["/posts.rb", 23]

        has_many :comments

        attribute :title
        attribute :body
      end

      source :comments do
        self.__source_location = [
          File.join(
            Pakyow::Support::System.local_framework_path_string,
            "pakyow-framework/comments.rb"
          ), 1
        ]

        attribute :body
      end
    end

    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  let :command do
    "info:sources"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mShow defined sources for an app\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow info:sources\n\n\e[1mOPTIONS\e[0m\n      --app=app  \e[33mThe app to run the command on\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "shows sources info" do
      expect(run_command(command)).to eq("\e[1m:comments\e[0m \e[34mpakyow/framework\e[0m\n  belongs_to :post\n\n  attribute :body, :string\n  attribute :created_at, :datetime\n  attribute :id, :bignum\n  attribute :post_id, :bignum\n  attribute :updated_at, :datetime\n\n\e[1m:posts\e[0m /posts.rb:23\n  has_many :comments\n\n  attribute :body, :string\n  attribute :created_at, :datetime\n  attribute :id, :bignum\n  attribute :title, :string\n  attribute :updated_at, :datetime\n\n")
    end

    it "needs more specific tests"
  end
end
