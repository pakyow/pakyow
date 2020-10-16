RSpec.describe "submitting invalid form data" do
  include_context "app"

  let :app_def do
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

  context "form submission and origin are both present" do
    it "reroutes to the origin" do
      expect_any_instance_of(Pakyow::Routing::Controller).to receive(:reroute).with("/posts/new", as: :bad_request, method: :get)
      expect(call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new") })[0]).to be(400)
    end

    it "adds an errored class to the form" do
      call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include('<form data-b="post:form" data-ui="form" class="ui-errored"')
      end
    end

    it "adds an errored class and error message title to each errored field" do
      call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include('<input type="text" data-b="body" name="post[body]" class="ui-errored" title="Body is required">')
      end
    end

    it "does not add an errored class or error message title to a non-errored field" do
      call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include('<input type="text" data-b="title" name="post[title]" class="" title="" value="foo title">')
      end
    end

    it "presents errors for the invalid submission" do
      call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        body = result[2]
        expect(body).to include_sans_whitespace("Body is required")
        expect(body).to include_sans_whitespace('<li data-b="error.message"')
      end
    end

    it "presents the submitted data" do
      call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form"), post: { title: "foo title"} }).tap do |result|
        expect(result[0]).to be(400)
        expect(result[2]).to include_sans_whitespace(
          <<~HTML
            <input type="text" data-b="title" name="post[title]" class="" title="" value="foo title">
          HTML
        )
      end
    end

    context "app handles the invalid submission" do
      let :app_def do
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
      let :app_def do
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
        call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form:bar"), post: { title: "bar title"} }).tap do |result|
          expect(result[0]).to be(400)
          result[2].tap do |body|
            expect(body).to include('<form data-b="post:form:foo" data-ui="form" class="foo"')
            expect(body).to include('<form data-b="post:form:bar" data-ui="form" class="bar ui-errored"')
          end
        end
      end

      it "presents the submitted data in the correct form" do
        call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form:bar"), post: { title: "bar title"} }).tap do |result|
          expect(result[0]).to be(400)
          result[2].tap do |body|
            expect(body).to include('<input type="text" data-b="title" class="foo" name="post[title]">')
            expect(body).to include('<input type="text" data-b="title" class="bar" name="post[title]" title="" value="bar title">')
          end
        end
      end
    end

    context "root data does not pass verification" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            disable_protection :csrf

            new do; end

            create do
              verify do
                required :post
              end
            end
          end
        end
      end

      it "presents errors for the invalid submission" do
        call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form") }).tap do |result|
          expect(result[0]).to be(400)
          expect(result[2]).to include_sans_whitespace("Post is required")
          expect(result[2]).to include_sans_whitespace('<li data-b="error.message"')
          expect(result[2]).to include_sans_whitespace('<ul data-ui="form-errors" class="">')
        end
      end

      context "form errors component does not have a scope" do
        let :app_def do
          Proc.new do
            resource :posts, "/posts" do
              disable_protection :csrf

              new do
                render "/posts/standalone"
              end

              create do
                verify do
                  required :post
                end
              end
            end
          end
        end

        it "presents the error component without specific errors" do
          call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form") }).tap do |result|
            expect(result[0]).to be(400)
            expect(result[2]).to include_sans_whitespace(
              <<~HTML
                <ul data-ui="form-errors" class="">
                  <li>
                    Error message goes here.
                  </li>
                </ul>
              HTML
            )
          end
        end
      end
    end
  end

  context "form submission is present but not the origin" do
    it "rejects the handling" do
      expect_any_instance_of(Pakyow::Routing::Controller).to receive(:reject)
      call("/posts", method: :post, params: { :"pw-form" => sign(id: 123) }).tap do |result|
        expect(result[0]).to be(400)
      end
    end
  end

  context "form submission is not present" do
    it "rejects the handling" do
      expect_any_instance_of(Pakyow::Routing::Controller).to receive(:reject)
      call("/posts", method: :post).tap do |result|
        expect(result[0]).to be(400)
      end
    end
  end
end
