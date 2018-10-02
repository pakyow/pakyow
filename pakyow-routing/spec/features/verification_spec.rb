RSpec.shared_examples "verification" do
  before do
    $verification_route = Proc.new do
      connection.body = params
    end
  end

  after do
    $verification = $verification_route = nil
  end

  describe "sanitization" do
    before do
      $verification = Proc.new do
        required :value1
        optional :value2
      end
    end

    it "allows required and optional values" do
      expect(call("/test", params: { value1: "foo", value2: "bar" })[2].body).to eq(value1: "foo", value2: "bar")
    end

    it "does not include values for unpassed optional values" do
      expect(call("/test", params: { value1: "foo" })[2].body).to eq(value1: "foo")
    end

    it "strips values not defined as required or optional" do
      expect(call("/test", params: { value1: "foo", value2: "bar", value3: "baz" })[2].body).to eq(value1: "foo", value2: "bar")
    end
  end

  describe "required values" do
    before do
      $verification = Proc.new do
        required :value1
        required :value2
        optional :value3
      end
    end

    context "a single required value is missing" do
      it "responds bad request" do
        expect(call("/test", params: { value1: "" })[0]).to eq(400)
      end
    end

    context "all required values are present" do
      it "responds ok" do
        expect(call("/test", params: { value1: "", value2: "" })[0]).to eq(200)
      end

      context "an optional value is present" do
        it "responds ok" do
          expect(call("/test", params: { value1: "", value2: "", value3: "" })[0]).to eq(200)
        end
      end
    end
  end

  describe "validation" do
    before do
      $verification = Proc.new do
        required :value1 do
          validate :presence
        end

        optional :value2 do
          validate :presence
        end
      end
    end

    context "required value passes validation" do
      it "responds ok" do
        expect(call("/test", params: { value1: "foo" })[0]).to eq(200)
      end
    end

    context "required value fails validation" do
      it "responds bad request" do
        expect(call("/test", params: { value1: "" })[0]).to eq(400)
      end
    end

    context "optional value is passed" do
      context "optional value passes validation" do
        it "responds ok" do
          expect(call("/test", params: { value1: "foo", value2: "bar" })[0]).to eq(200)
        end
      end

      context "optional value fails validation" do
        it "responds bad request" do
          expect(call("/test", params: { value1: "foo", value2: "" })[0]).to eq(400)
        end
      end
    end
  end
end

RSpec.shared_examples "nested verification" do
  before do
    $verification_route = Proc.new do
      connection.body = params
    end
  end

  after do
    $verification = $verification_route = nil
  end

  describe "sanitization" do
    before do
      $verification = Proc.new do
        required :value1 do
          required :value2
          optional :value3
        end
      end
    end

    it "allows required and optional values" do
      expect(call("/test", params: { value1: { value2: "bar", value3: "baz" } })[2].body).to eq(value1: { value2: "bar", value3: "baz" })
    end

    it "strips values not defined as required or optional" do
      expect(call("/test", params: { value1: { value2: "bar", value3: "baz", value4: "qux" }, value5: "" })[2].body).to eq(value1: { value2: "bar", value3: "baz" })
    end
  end

  describe "required values" do
    before do
      $verification = Proc.new do
        required :value1 do
          required :value2
          optional :value3
        end
      end
    end

    context "a single required value is missing" do
      it "responds bad request" do
        expect(call("/test", params: { value1: { } })[0]).to eq(400)
      end
    end

    context "all required values are present" do
      it "responds ok" do
        expect(call("/test", params: { value1: { value2: "" } })[0]).to eq(200)
      end

      context "an optional value is present" do
        it "responds ok" do
          expect(call("/test", params: { value1: { value2: "", value3: "" } })[0]).to eq(200)
        end
      end
    end
  end

  describe "validation" do
    before do
      $verification = Proc.new do
        required :value1 do
          required :value2 do
            validate :presence
          end

          optional :value3 do
            validate :presence
          end
        end
      end
    end

    context "required value passes validation" do
      it "responds ok" do
        expect(call("/test", params: { value1: { value2: "foo" } })[0]).to eq(200)
      end
    end

    context "required value fails validation" do
      it "responds bad request" do
        expect(call("/test", params: { value1: { value2: "" } })[0]).to eq(400)
      end
    end

    context "optional value is passed" do
      context "optional value passes validation" do
        it "responds ok" do
          expect(call("/test", params: { value1: { value2: "foo", value3: "bar" } })[0]).to eq(200)
        end
      end

      context "optional value fails validation" do
        it "responds bad request" do
          expect(call("/test", params: { value1: { value2: "foo", value3: "" } })[0]).to eq(400)
        end
      end
    end
  end
end

RSpec.describe "verifying all routes in a controller" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      controller do
        verify do
          instance_exec(&$verification)
        end

        get :test, "/test" do
          instance_exec(&$verification_route)
        end
      end
    end
  end

  include_examples "verification"
  include_examples "nested verification"
end

RSpec.describe "verifying a specific route in a controller" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      controller do
        verify :test do
          instance_exec(&$verification)
        end

        get :test, "/test" do
          instance_exec(&$verification_route)
        end
      end
    end
  end

  include_examples "verification"
  include_examples "nested verification"
end

RSpec.describe "verifying inside of a route" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      controller do
        get :test, "/test" do
          verify do
            instance_exec(&$verification)
          end

          instance_exec(&$verification_route)
        end
      end
    end
  end

  include_examples "verification"
  include_examples "nested verification"
end

RSpec.describe "handling failed verification" do
  context "without a custom handler" do
    include_context "testable app"

    let :app_definition do
      Proc.new do
        controller do
          verify :test do
            required :value
          end

          get :test, "/test"
        end
      end
    end

    it "automatically responds as a bad request" do
      expect(call("/test")[0]).to eq(400)
    end
  end

  context "with a custom handler" do
    include_context "testable app"

    let :app_definition do
      Proc.new do
        controller do
          handle Pakyow::InvalidData, as: :not_found

          verify :test do
            required :value
          end

          get :test, "/test"
        end
      end
    end

    it "is possible to use a custom handler instead" do
      expect(call("/test")[0]).to eq(404)
    end
  end
end

RSpec.describe "setting allowed params" do
  include_context "testable app"

  context "verified in the controller" do
    let :app_definition do
      Proc.new do
        controller do
          allow_params :value1

          verify :test do
            required :value2
          end

          get :test, "/test" do
            send params.to_json
          end
        end
      end
    end

    it "allows allowed params" do
      call("/test", params: { value1: "one", value2: "two" }).tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.read).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end

  context "verified in the route" do
    let :app_definition do
      Proc.new do
        controller do
          allow_params :value1

          get :test, "/test" do
            verify do
              required :value2
            end

            send params.to_json
          end
        end
      end
    end

    it "allows allowed params" do
      call("/test", params: { value1: "one", value2: "two" }).tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.read).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end

  context "allow params is called twice" do
    let :app_definition do
      Proc.new do
        controller do
          allow_params :value1
          allow_params :value2

          get :test, "/test" do
            verify do
            end

            send params.to_json
          end
        end
      end
    end

    it "allows all allowed params" do
      call("/test", params: { value1: "one", value2: "two" }).tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.read).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end

  describe "inheriting allowed params" do
    let :app_definition do
      Proc.new do
        isolated :Controller do
          allow_params :value2
        end

        controller do
          get :test, "/test" do
            verify do
              required :value1
            end

            send params.to_json
          end
        end
      end
    end

    it "inherits allowed params from a parent controller" do
      call("/test", params: { value1: "one", value2: "two" }).tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.read).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end
end

RSpec.describe "allowing resource ids" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      resource :posts, "/posts" do
        show do
          verify do
          end

          send params.to_json
        end

        resource :comments, "/comments" do
          show do
            verify do
            end

            send params.to_json
          end
        end
      end
    end
  end

  it "allows top level resource ids" do
    call("/posts/1").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body.read).to eq('{"id":"1"}')
    end
  end

  it "allows nested resource ids" do
    call("/posts/1/comments/2").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body.read).to eq('{"post_id":"1","id":"2"}')
    end
  end
end
