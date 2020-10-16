require "pakyow/cli"

RSpec.describe "cli: info:endpoints" do
  include_context "app"
  include_context "command"

  let(:endpoint_class) {
    Class.new do
      attr_reader :method, :name, :path, :source_location

      def initialize(method:, name:, path:, source_location:)
        @method = method
        @name = name
        @path = path
        @source_location = source_location
      end
    end
  }

  let(:app_def) {
    local = self

    Proc.new {
      after :initialize do
        endpoints << local.endpoint_class.new(
          method: :get,
          name: :foo,
          path: "/foo",
          source_location: ["/foo.rb", 23]
        )

        endpoints << local.endpoint_class.new(
          method: :post,
          name: :pakyow,
          path: "/pakyow",
          source_location: [
            File.join(
              Pakyow::Support::System.local_framework_path_string,
              "pakyow-framework/endpoint.rb"
            ), 1
          ]
        )

        endpoints << local.endpoint_class.new(
          method: :get,
          name: :aaa,
          path: "/aaa",
          source_location: ["/aaa.rb", 1]
        )
      end
    }
  }

  let :command do
    "info:endpoints"
  end

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/info/endpoints/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    it "shows endpoints info" do
      expect(run_command(command, project: true)).to eq(":aaa     GET   /aaa     /aaa.rb:1       \n:foo     GET   /foo     /foo.rb:23      \n:pakyow  POST  /pakyow  \e[34mpakyow/framework\e[0m\n")
    end

    it "needs more specific tests"
  end
end
