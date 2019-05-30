RSpec.describe "submitting invalid form data" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        new do; end

        create do
          verify do
            required :post do
              required :title
              required :body
            end
          end
        end
      end
    end
  end

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  def sign(metadata)
    Pakyow::Support::MessageVerifier.new.sign(metadata.to_json)
  end

  context "form submission is present" do
    it "reroutes to the origin" do
      expect_any_instance_of(Pakyow::Controller).to receive(:reroute).with("/posts/new", as: :bad_request, method: :get)
      expect(call("/posts", method: :post, params: { _form: sign(origin: "/posts/new") })[0]).to be(400)
    end

    it "adds an errored class to the form" do
      call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include('<form data-b="post" data-ui="form" data-c="form" class="errored"')
      end
    end

    it "adds an errored class to each errored field" do
      call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include('<input type="text" data-b="body" data-c="form" name="post[body]" class="errored">')
      end
    end

    it "does not add an errored class to a non-errored field" do
      call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include('<input type="text" data-b="title" data-c="form" name="post[title]" class="" value="foo title">')
      end
    end

    it "presents errors for the invalid submission" do
      call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        body = result[2]
        expect(body).to include_sans_whitespace("Body is required")
        expect(body).to include_sans_whitespace('<li data-b="error.message" data-c="form"')
      end
    end

    it "presents the submitted data" do
      call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include_sans_whitespace(
          <<~HTML
            <input type="text" data-b="title" data-c="form" name="post[title]" class="" value="foo title">
          HTML
        )
      end
    end

    context "app handles the invalid submission" do
      let :app_init do
        Proc.new do
          resource :post, "/posts" do
            disable_protection :csrf

            handle Pakyow::InvalidData, as: :unauthorized do
              connection.body = StringIO.new("handled")
            end

            new do; end

            create do
              verify do
                required :post do
                  required :title
                  required :body
                end
              end
            end
          end
        end
      end

      it "does not call the form submission handler" do
        call("/posts", method: :post).tap do |result|
          expect(result[0]).to be(401)
          expect(result[2]).to eq("handled")
        end
      end
    end

    context "multiple forms are present with channeled bindings" do
      let :app_init do
        Proc.new do
          resource :post, "/posts" do
            disable_protection :csrf

            new do
              render "/posts/multiple"
            end

            create do
              verify do
                required :post do
                  required :title
                  required :body
                end
              end
            end
          end
        end
      end

      it "sets up the correct form as errored" do
        call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form:bar"), post: { title: "bar title"} }).tap do |result|
          expect(result[0]).to be(400)
          result[2].tap do |body|
            expect(body).to include('<form data-b="post" data-ui="form" class="foo" data-c="form:foo"')
            expect(body).to include('<form data-b="post" data-ui="form" class="bar errored" data-c="form:bar"')
          end
        end
      end

      it "presents the submitted data in the correct form" do
        call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form:bar"), post: { title: "bar title"} }).tap do |result|
          expect(result[0]).to be(400)
          result[2].tap do |body|
            expect(body).to include('<input type="text" data-b="title" class="foo" data-c="form" name="post[title]">')
            expect(body).to include('<input type="text" data-b="title" class="bar" data-c="form" name="post[title]" value="bar title">')
          end
        end
      end
    end
  end

  context "form submission is not present" do
    it "rejects the handling" do
      expect_any_instance_of(Pakyow::Controller).to receive(:reject)
      call("/posts", method: :post).tap do |result|
        expect(result[0]).to be(400)
      end
    end
  end
end
