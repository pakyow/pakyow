RSpec.describe "submitting invalid form data via ui" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        skip :clear_form_errors
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

  describe "the initial render" do
    it "presents with an ephemeral source qualified with the form errors id" do
      expect(SecureRandom).to receive(:hex).at_least(:once).and_return("foo123")
      expect_any_instance_of(Pakyow::Data::Lookup).to receive(:ephemeral).with(:errors, form_id: "foo123").and_call_original
      call("/posts/new").tap do |result|
        expect(result[0]).to eq(200)
      end
    end

    it "sets the form as subscribed" do
      call("/posts/new").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2]).to include_sans_whitespace('<form data-b="post" data-ui="form" data-c="form" class="" action="/posts" method="post" data-t="')
      end
    end
  end

  context "form submission is present" do
    it "causes the form errors to mutate" do
      ephemeral_double = double(:ephemeral)
      expect(ephemeral_double).to receive(:set).with([{:field=>:title,:message=>"Title is required"}, {:field=>:body,:message=>"Body is required"}])
      expect_any_instance_of(Pakyow::Data::Lookup).to receive(:ephemeral) { |lookup, type, **qualifications|
        expect(type).to eq(:errors)
        expect(qualifications).to eq(form_id: "foo123")
      }.and_return(ephemeral_double)
      expect(call("/posts", method: :post, params: { _form: sign(id: "foo123") }, headers: { "Pw-Ui" => "true" })[0]).to be(400)
    end

    it "does not reroute" do
      expect_any_instance_of(Pakyow::Controller).to_not receive(:reroute)
      expect(call("/posts", method: :post, params: { _form: sign(origin: "/posts/new", binding: "post:form") }, headers: { "Pw-Ui" => "true" })[0]).to be(400)
    end

    context "app handles the invalid submission" do
      let :app_init do
        Proc.new do
          resource :post, "/posts" do
            disable_protection :csrf

            handle Pakyow::InvalidData, as: :unauthorized do
              send "handled"
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
        call("/posts", method: :post, headers: { "Pw-Ui" => "true" }).tap do |result|
          expect(result[0]).to be(401)
          expect(result[2]).to eq("handled")
        end
      end
    end
  end

  context "form submission is not present" do
    it "rejects the handling" do
      expect_any_instance_of(Pakyow::Controller).to receive(:reject)
      call("/posts", method: :post, headers: { "Pw-Ui" => "true" }).tap do |result|
        expect(result[0]).to be(400)
      end
    end
  end

  describe "clearing form errors" do
    let :app_init do
      Proc.new do
        resource :post, "/posts" do
          disable_protection :csrf

          new do; end

          create do
          end
        end
      end
    end

    it "clears the form errors" do
      ephemeral_double = double(:ephemeral)
      expect(ephemeral_double).to receive(:set).with([])
      expect_any_instance_of(Pakyow::Data::Lookup).to receive(:ephemeral) { |lookup, type, **qualifications|
        expect(type).to eq(:errors)
        expect(qualifications).to eq(form_id: "foo123")
      }.and_return(ephemeral_double)
      expect(call("/posts", method: :post, params: { _form: sign(id: "foo123") }, headers: { "Pw-Ui" => "true" })[0]).to be(200)
    end
  end
end
