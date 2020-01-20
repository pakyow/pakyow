require "pakyow/plugin"

RSpec.describe "global view versioning from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      on "load" do
        isolated(:Presenter) do
          version :"for-current-user" do |object, plug|
            object[:user_id] == 2
          end
        end

        presenter "/test-plugin/versioning" do
          render :post do
            present([
              { title: "foo", user_id: 1 },
              { title: "bar", user_id: 2 },
              { title: "baz", user_id: 3 }
            ])
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

      presenter "/versions/plugin/default" do
        render :post do
          present([
            { title: "foo", user_id: 1 },
            { title: "bar", user_id: 2 },
            { title: "baz", user_id: 3 }
          ])
        end
      end

      presenter "/versions/plugin/specific" do
        render :post do
          present([
            { title: "foo", user_id: 1 },
            { title: "bar", user_id: 2 },
            { title: "baz", user_id: 3 }
          ])
        end
      end
    end
  end

  it "uses versions within the default plugin" do
    call("/test-plugin/versioning").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">foo</h1>

            default
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="for-current-user">
            <h1 data-b="title">bar</h1>

            for current user
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">baz</h1>

            default
          </div>
        HTML
      )
    end
  end

  it "uses versions within the named plugin" do
    call("/foo/test-plugin/versioning").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">foo</h1>

            default
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="for-current-user">
            <h1 data-b="title">bar</h1>

            for current user
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">baz</h1>

            default
          </div>
        HTML
      )
    end
  end

  it "uses versions within the app for the default instance" do
    call("/versions/plugin/default").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">foo</h1>

            default
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="@testable.for-current-user">
            <h1 data-b="title">bar</h1>

            for current user
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">baz</h1>

            default
          </div>
        HTML
      )
    end
  end

  it "uses versions within the app for the named instance" do
    call("/versions/plugin/specific").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">foo</h1>

            default
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="@testable(foo).for-current-user">
            <h1 data-b="title">bar</h1>

            for current user
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">baz</h1>

            default
          </div>
        HTML
      )
    end
  end

  context "presenting implicitly" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/"

        configure do
          config.root = File.join(__dir__, "support/app")
        end

        controller do
          default do
            expose :posts, [
              { title: "foo", user_id: 1 },
              { title: "bar", user_id: 2 },
              { title: "baz", user_id: 3 }
            ]

            render "/versions/plugin/default"
          end
        end
      end
    end

    it "uses versions" do
      call("/").tap do |result|
        expect(result[0]).to eq(200)
        response_body = result[2]

        expect(response_body).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <h1 data-b="title">foo</h1>

              default
            </div>
          HTML
        )

        expect(response_body).to include_sans_whitespace(
          <<~HTML
            <div data-b="post" data-v="@testable.for-current-user">
              <h1 data-b="title">bar</h1>

              for current user
            </div>
          HTML
        )

        expect(response_body).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <h1 data-b="title">baz</h1>

              default
            </div>
          HTML
        )
      end
    end
  end
end

RSpec.describe "using global versions defined in a plugin from another plugin" do
  before do
    class TestPluginFoo < Pakyow::Plugin(:testable_foo, File.join(__dir__, "support/plugin"))
      on "load" do
        isolated(:Presenter) do
          version :"for-current-user" do |object, plug|
            object[:user_id] == 2
          end
        end
      end
    end

    class TestPluginBar < Pakyow::Plugin(:testable_bar, File.join(__dir__, "support/plugin-bar"))
      on "load" do
        presenter "/test-plugin/versioning" do
          render :post do
            present([
              { title: "foo", user_id: 1 },
              { title: "bar", user_id: 2 },
              { title: "baz", user_id: 3 }
            ])
          end
        end
      end
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

  it "uses versions from the plugin" do
    call("/bar/test-plugin/versioning").tap do |result|
      expect(result[0]).to eq(200)
      response_body = result[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">foo</h1>

            default
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="@testable_foo.for-current-user">
            <h1 data-b="title">bar</h1>

            for current user
          </div>
        HTML
      )

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">baz</h1>

            default
          </div>
        HTML
      )
    end
  end
end
