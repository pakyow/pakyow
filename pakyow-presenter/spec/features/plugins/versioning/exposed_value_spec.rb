require "pakyow/plugin"

RSpec.describe "global view versioning from a plugin based on exposed values" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "../support/plugin"))
      on "initialize" do
        isolated(:Presenter) do
          version :"for-current-user" do |object, plug|
            value = if plug
              presentables[plug.exposed_value_name(:__current_user)]
            else
              presentables[:__current_user]
            end

            object[:user_id] == value[:id]
          end
        end

        isolated(:Renderer) do
          expose do |connection, plug|
            name = if plug
              plug.exposed_value_name(:__current_user)
            else
              :__current_user
            end

            connection.set(name, { id: 2 })
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
        config.root = File.join(__dir__, "../support/app")
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

  it "has access to the correct value within the default plugin" do
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

  it "has access to the correct value within the named plugin" do
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

  it "has access to the correct value for the default instance" do
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
          <div data-b="post" data-v="testable.for-current-user">
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

  it "has access to the correct value for the named instance" do
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
          <div data-b="post" data-v="testable(foo).for-current-user">
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
