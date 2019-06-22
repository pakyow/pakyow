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
