require "pakyow/plugin"

RSpec.describe "rendering view templates" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_definition do
    Proc.new {
      plug :testable, at: "/"

      configure :prototype do
        config.root = File.join(__dir__, "support/app")
      end
    }
  end

  let :mode do
    :prototype
  end

  it "serves the plugin view prototype" do
    call("test-plugin/render/prototype").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2].body.read
      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <title>app default</title>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          plugin prototype
        HTML
      )
    end
  end
end
