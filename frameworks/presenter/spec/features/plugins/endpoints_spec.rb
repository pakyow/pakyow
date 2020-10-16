require "pakyow/plugin"

RSpec.describe "using endpoints defined in plugins" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      on :load do
        controller do
          get :root, "/"
        end
      end
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"
      plug :testable, at: "/foo", as: :foo

      configure do
        config.root = File.join(__dir__, "support/app")
      end
    end
  end

  it "uses endpoints for the default instance" do
    call("/endpoints/plugin/default").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <a data-e="@testable.root" href="/" class="ui-active">
            test endpoint
          </a>
        HTML
      )
    end
  end

  it "uses endpoints for the named instance" do
    call("/endpoints/plugin/specific").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <a data-e="@testable(foo).root" href="/foo">
            test endpoint
          </a>
        HTML
      )
    end
  end
end
