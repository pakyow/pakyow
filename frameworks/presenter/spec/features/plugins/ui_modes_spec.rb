require "pakyow/plugin"

RSpec.describe "using ui modes defined in plugins" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      on "initialize" do
        mode :test1 do
          true
        end

        mode :test2 do
          false
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

  it "uses modes for the default instance" do
    call("/modes/plugin/default").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div>test1</div>
        HTML
      )

      expect(response_body).not_to include_sans_whitespace(
        <<~HTML
          <div>test2</div>
        HTML
      )
    end
  end

  it "uses modes for the named instance" do
    call("/modes/plugin/specific").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div>test1</div>
        HTML
      )

      expect(response_body).not_to include_sans_whitespace(
        <<~HTML
          <div>test2</div>
        HTML
      )
    end
  end
end

RSpec.describe "using ui modes defined in a plugin from another plugin" do
  before do
    class TestPluginFoo < Pakyow::Plugin(:testable_foo, File.join(__dir__, "support/plugin"))
      on "initialize" do
        mode :test1 do
          true
        end

        mode :test2 do
          false
        end
      end
    end

    class TestPluginBar < Pakyow::Plugin(:testable_bar, File.join(__dir__, "support/plugin-bar"))
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable_foo, at: "/"
      plug :testable_bar, at: "/bar"

      configure do
        config.root = File.join(__dir__, "support/app")
      end
    end
  end

  it "uses modes correctly" do
    call("/bar/modes/plugin/default").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div>test1</div>
        HTML
      )

      expect(response_body).not_to include_sans_whitespace(
        <<~HTML
          <div>test2</div>
        HTML
      )
    end
  end
end
