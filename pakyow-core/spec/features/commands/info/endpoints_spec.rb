require "pakyow/cli"

RSpec.describe "cli: info:endpoints" do
  include_context "command"

  before do
    endpoint_class = Class.new do
      attr_reader :method, :name, :path, :source_location

      def initialize(method:, name:, path:, source_location:)
        @method = method
        @name = name
        @path = path
        @source_location = source_location
      end
    end

    Pakyow.app :test do
      after :initialize do
        endpoints << endpoint_class.new(
          method: :get,
          name: :foo,
          path: "/foo",
          source_location: ["/foo.rb", 23]
        )

        endpoints << endpoint_class.new(
          method: :post,
          name: :pakyow,
          path: "/pakyow",
          source_location: [
            File.join(
              Pakyow::Support::Dependencies.local_framework_path,
              "pakyow-framework/endpoint.rb"
            ), 1
          ]
        )

        endpoints << endpoint_class.new(
          method: :get,
          name: :aaa,
          path: "/aaa",
          source_location: ["/aaa.rb", 1]
        )
      end
    end

    allow_any_instance_of(Pakyow::CLI).to receive(:project_context?).and_return(true)
  end

  let :command do
    "info:endpoints"
  end

  describe "help" do
    it "is helpful" do
      expect(run_command(command, "-h")).to eq("\e[34;1mShow defined endpoints for an app\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow info:endpoints\n\n\e[1mOPTIONS\e[0m\n      --app=app  \e[33mThe app to run the command on\e[0m\n  -e, --env=env  \e[33mWhat environment to use\e[0m\n")
    end
  end

  describe "running" do
    it "shows endpoints info" do
      expect(run_command(command)).to eq(":aaa     GET   /aaa     /aaa.rb:1       \n:foo     GET   /foo     /foo.rb:23      \n:pakyow  POST  /pakyow  \e[34mpakyow/framework\e[0m\n")
    end

    it "needs more specific tests"
  end
end
