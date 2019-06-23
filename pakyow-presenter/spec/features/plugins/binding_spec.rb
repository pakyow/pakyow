require "pakyow/plugin"

RSpec.describe "binding values through a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
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

      presenter "/binding" do
        render :post do
          present(title: "post 1")
        end
      end

      presenter "/binding/named" do
        render :post do
          present(title: "post 1")
        end
      end
    end
  end

  it "binds values to the default instance" do
    expect(call("/binding")[2]).to include_sans_whitespace(
      <<~HTML
        <article data-b="post" data-c="article">
          <h1 data-b="plugged_title" data-c="article">testable: post 1</h1>
        </article>
      HTML
    )
  end

  it "binds values to the named instance" do
    expect(call("/binding/named")[2]).to include_sans_whitespace(
      <<~HTML
        <article data-b="post" data-c="article">
          <h1 data-b="plugged_title" data-c="article">testable_foo: post 1</h1>
        </article>
      HTML
    )
  end
end

RSpec.describe "binding values exposed by the plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      on :initialize do
        plug = self
        parent.isolated(:Renderer) do
          expose do |connection|
            connection.set(plug.frontend_key(:post), { title: "plugin title" })
          end
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

  it "binds values to the default instance" do
    expect(call("/binding")[2]).to include_sans_whitespace(
      <<~HTML
        <article data-b="post" data-c="article">
          <h1 data-b="plugged_title" data-c="article">testable: plugin title</h1>
        </article>
      HTML
    )
  end

  it "binds values to the named instance" do
    expect(call("/binding/named")[2]).to include_sans_whitespace(
      <<~HTML
        <article data-b="post" data-c="article">
          <h1 data-b="plugged_title" data-c="article">testable_foo: plugin title</h1>
        </article>
      HTML
    )
  end

  describe "overriding plugin values from the app" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/"
        plug :testable, at: "/foo", as: :foo

        configure do
          config.root = File.join(__dir__, "support/app")
        end

        controller :binding, "/binding" do
          default do
            expose :post, { title: "app title" }
          end
        end
      end
    end

    it "gives precedence to the app values" do
      expect(call("/binding")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article">
            <h1 data-b="plugged_title" data-c="article">testable: app title</h1>
          </article>
        HTML
      )
    end
  end
end
