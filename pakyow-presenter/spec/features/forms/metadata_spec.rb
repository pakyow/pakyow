RSpec.describe "form metadata" do
  include_context "app"

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  let :response do
    call("/form")
  end

  let :metadata do
    response_body = response[2]
    expect(response_body).to include("input type=\"hidden\" name=\"pw-form\"")

    JSON.parse(
      Pakyow::Support::MessageVerifier.new("key").verify(
        response_body.match(/name=\"pw-form\" value=\"([^\"]+)\"/)[1]
      )
    )
  end

  context "form is not setup explicitly" do
    it "securely embeds the form id" do
      expect(metadata["id"].length).to eq(48)
    end

    it "securely embeds the form binding" do
      expect(metadata["binding"]).to eq("post:form")
    end

    it "securely embeds the form origin" do
      expect(metadata["origin"]).to eq("/form")
    end

    context "form is being re-rendered" do
      let :response do
        verifier = Pakyow::Support::MessageVerifier.new("key")
        call("/", method: :post, params: { :"pw-form" => verifier.sign({ origin: "/foo" }.to_json) })
      end

      let :app_def do
        Proc.new do
          controller do
            disable_protection :csrf

            post "/" do
              render "/form"
            end
          end
        end
      end

      it "embeds the origin from the original submission" do
        expect(metadata["origin"]).to eq("/foo")
      end
    end

    context "metadata set during presenter perform" do
      let :app_def do
        Proc.new do
          presenter "/form" do
            render node: -> { forms[0] } do
              view.label(:form)[:foo] = "bar"
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
    let :app_def do
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
      let :app_def do
        Proc.new {
          resource :posts, "/posts" do
            create do; end
          end

          presenter "/form" do
            render node: -> { form(:post) } do
              create
              view.label(:form)[:foo] = "bar"
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
