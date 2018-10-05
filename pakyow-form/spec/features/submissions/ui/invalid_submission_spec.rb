RSpec.describe "submitting invalid form data via ui" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$form_app_boilerplate)

      resource :post, "/posts" do
        skip_action :clear_form_errors
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
        expect(result[2].body.read).to include_sans_whitespace('<form data-b="post" data-ui="form" data-c="form" method="post" class="" data-t="')
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
      expect(call("/posts", method: :post, params: { form: { id: "foo123" } }, Pakyow::UI::Helpers::UI_REQUEST_HEADER => "true")[0]).to be(400)
    end

    it "does not reroute" do
      expect_any_instance_of(Pakyow::Controller).to_not receive(:reroute)
      expect(call("/posts", method: :post, params: { form: { origin: "/posts/new" } }, Pakyow::UI::Helpers::UI_REQUEST_HEADER => "true")[0]).to be(400)
    end

    context "app handles the invalid submission" do
      let :app_definition do
        Proc.new do
          instance_exec(&$form_app_boilerplate)

          resource :post, "/posts" do
            disable_protection :csrf

            handle Pakyow::InvalidData, as: :unauthorized do
              res.body << "handled"
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
        call("/posts", method: :post, Pakyow::UI::Helpers::UI_REQUEST_HEADER => "true").tap do |result|
          expect(result[0]).to be(401)
          expect(result[2].body.join).to eq("handled")
        end
      end
    end
  end

  context "form submission is not present" do
    it "rejects the handling" do
      expect_any_instance_of(Pakyow::Controller).to receive(:reject)
      call("/posts", method: :post, Pakyow::UI::Helpers::UI_REQUEST_HEADER => "true").tap do |result|
        expect(result[0]).to be(400)
      end
    end
  end

  describe "clearing form errors" do
    let :app_definition do
      Proc.new do
        instance_exec(&$form_app_boilerplate)

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
      expect(call("/posts", method: :post, params: { form: { id: "foo123" } }, Pakyow::UI::Helpers::UI_REQUEST_HEADER => "true")[0]).to be(200)
    end
  end
end
