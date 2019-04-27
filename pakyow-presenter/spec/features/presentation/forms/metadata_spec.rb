RSpec.describe "form metadata" do
  include_context "app"

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  let :metadata do
    response = call("/form")
    expect(response[0]).to eq(200)

    response_body = response[2]
    expect(response_body).to include("input type=\"hidden\" name=\"_form\"")

    JSON.parse(
      Pakyow::Support::MessageVerifier.new("key").verify(
        response_body.match(/name=\"_form\" value=\"([^\"]+)\"/)[1]
      )
    )
  end

  context "form is not setup explicitly" do
    it "securely embeds form metadata" do
      expect(metadata["id"].length).to eq(48)
    end

    context "metadata set during presenter perform" do
      let :app_init do
        Proc.new do
          presenter "/form" do
            render node: -> { forms[0] } do
              view.label(:metadata)[:foo] = "bar"
            end
          end
        end
      end

      it "embeds the metadata value" do
        expect(metadata["foo"]).to include("bar")
      end
    end
  end

  context "form is setup explicitly" do
    let :app_init do
      Proc.new {
        resource :posts, "/posts" do
          create do; end
        end

        presenter "/form" do
          render node: -> { form(:post) } do
            create
          end
        end
      }
    end

    it "securely embeds form metadata" do
      expect(metadata["id"].length).to eq(48)
    end

    context "metadata set during presenter perform" do
      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            create do; end
          end

          presenter "/form" do
            render node: -> { form(:post) } do
              create
              view.label(:metadata)[:foo] = "bar"
            end
          end
        }
      end

      it "embeds the metadata value" do
        expect(metadata["foo"]).to include("bar")
      end
    end
  end
end
