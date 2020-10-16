RSpec.shared_context "verification helpers" do
  def response(params)
    call("/test", input: StringIO.new(params.to_json), headers: { "content-type" => "application/json" })
  end
end

RSpec.shared_examples "verification" do
  describe "sanitization" do
    let(:verify_def) {
      Proc.new {
        required :value1
        optional :value2
      }
    }

    it "allows required and optional values" do
      expect(Marshal.load(response(value1: "foo", value2: "bar")[2])).to eq(value1: "foo", value2: "bar")
    end

    it "does not include values for unpassed optional values" do
      expect(Marshal.load(response(value1: "foo")[2])).to eq(value1: "foo")
    end

    it "strips values not defined as required or optional" do
      expect(Marshal.load(response(value1: "foo", value2: "bar", value3: "baz")[2])).to eq(value1: "foo", value2: "bar")
    end
  end

  describe "required values" do
    let(:verify_def) {
      Proc.new {
        required :value1
        required :value2
        optional :value3
      }
    }

    context "a single required value is missing" do
      it "responds bad request" do
        expect(response(value1: "")[0]).to eq(400)
      end
    end

    context "all required values are present" do
      it "responds ok" do
        expect(response(value1: "", value2: "")[0]).to eq(200)
      end

      context "an optional value is present" do
        it "responds ok" do
          expect(response(value1: "", value2: "", value3: "")[0]).to eq(200)
        end
      end
    end
  end

  describe "validation" do
    let(:verify_def) {
      Proc.new {
        required :value1 do
          validate :presence
        end

        optional :value2 do
          validate :presence
        end
      }
    }

    context "required value passes validation" do
      it "responds ok" do
        expect(response(value1: "foo")[0]).to eq(200)
      end
    end

    context "required value fails validation" do
      it "responds bad request" do
        expect(response(value1: "")[0]).to eq(400)
      end
    end

    context "optional value is passed" do
      context "optional value passes validation" do
        it "responds ok" do
          expect(response(value1: "foo", value2: "bar")[0]).to eq(200)
        end
      end

      context "optional value fails validation" do
        it "responds bad request" do
          expect(response(value1: "foo", value2: "")[0]).to eq(400)
        end
      end
    end
  end
end

RSpec.shared_examples "nested verification" do
  describe "sanitization" do
    let(:verify_def) {
      Proc.new {
        required :value1 do
          required :value2
          optional :value3
        end
      }
    }

    it "allows required and optional values" do
      expect(Marshal.load(response(value1: { value2: "bar", value3: "baz" })[2])).to eq(value1: { value2: "bar", value3: "baz" })
    end

    it "strips values not defined as required or optional" do
      expect(Marshal.load(response(value1: { value2: "bar", value3: "baz", value4: "qux" }, value5: "")[2])).to eq(value1: { value2: "bar", value3: "baz" })
    end

    context "with a value list" do
      it "allows required and optional values for each" do
        expect(Marshal.load(response(value1: [{ value2: "bar", value3: "baz" }, { value2: "qux", value3: "quux" }])[2])).to eq(value1: [{ value2: "bar", value3: "baz" }, { value2: "qux", value3: "quux" }])
      end

      it "strips values not defined as required or optional for each" do
        expect(Marshal.load(response(value1: [{ value2: "bar", value3: "baz", value4: "qux" }, { value2: "quux", value3: "corge", value4: "uier" }], value5: "")[2])).to eq(value1: [{ value2: "bar", value3: "baz" }, { value2: "quux", value3: "corge" }])
      end
    end
  end

  describe "required values" do
    let(:verify_def) {
      Proc.new {
        required :value1 do
          required :value2
          optional :value3
        end
      }
    }

    context "a single required value is missing" do
      it "responds bad request" do
        expect(response(value1: { })[0]).to eq(400)
      end

      context "with a value list" do
        it "responds bad request" do
          expect(response(value1: [{ }])[0]).to eq(400)
        end
      end
    end

    context "all required values are present" do
      it "responds ok" do
        expect(response(value1: { value2: "" })[0]).to eq(200)
      end

      context "with a value list" do
        it "responds ok" do
          expect(response(value1: [{ value2: "" }])[0]).to eq(200)
        end
      end

      context "an optional value is present" do
        it "responds ok" do
          expect(response(value1: { value2: "", value3: "" })[0]).to eq(200)
        end

        context "with a value list" do
          it "responds ok" do
            expect(response(value1: [{ value2: "", value3: "" }])[0]).to eq(200)
          end
        end
      end
    end
  end

  describe "validation" do
    let(:verify_def) {
      Proc.new {
        required :value1 do
          required :value2 do
            validate :presence
          end

          optional :value3 do
            validate :presence
          end
        end
      }
    }

    context "required value passes validation" do
      it "responds ok" do
        expect(response(value1: { value2: "foo" })[0]).to eq(200)
      end

      context "with a value list" do
        it "responds ok" do
          expect(response(value1: [{ value2: "foo" }])[0]).to eq(200)
        end
      end
    end

    context "required value fails validation" do
      it "responds bad request" do
        expect(response(value1: { value2: "" })[0]).to eq(400)
      end

      context "with a value list" do
        it "responds bad request" do
          expect(response(value1: [{ value2: "" }])[0]).to eq(400)
        end
      end
    end

    context "optional value is passed" do
      context "optional value passes validation" do
        it "responds ok" do
          expect(response(value1: { value2: "foo", value3: "bar" })[0]).to eq(200)
        end

        context "with a value list" do
          it "responds ok" do
            expect(response(value1: [{ value2: "foo", value3: "bar" }])[0]).to eq(200)
          end
        end
      end

      context "optional value fails validation" do
        it "responds bad request" do
          expect(response(value1: { value2: "foo", value3: "" })[0]).to eq(400)
        end

        context "with a value list" do
          it "responds bad request" do
            expect(response(value1: [{ value2: "foo", value3: "" }])[0]).to eq(400)
          end
        end
      end
    end
  end
end

RSpec.describe "verifying all routes in a controller" do
  include_context "app"
  include_context "verification helpers"

  let(:app_def) {
    local = self
    Proc.new {
      controller do
        verify do
          instance_eval(&local.verify_def)
        end

        get :test, "/test" do
          connection.body = StringIO.new(Marshal.dump(params))
        end
      end
    }
  }

  include_examples "verification"
  include_examples "nested verification"
end

RSpec.describe "verifying a specific route in a controller" do
  include_context "app"
  include_context "verification helpers"

  let(:app_def) {
    local = self
    Proc.new {
      controller do
        verify :test do
          instance_eval(&local.verify_def)
        end

        get :test, "/test" do
          connection.body = StringIO.new(Marshal.dump(params))
        end
      end
    }
  }

  include_examples "verification"
  include_examples "nested verification"
end

RSpec.describe "verifying inside of a route" do
  include_context "app"
  include_context "verification helpers"

  let(:app_def) {
    local = self
    Proc.new {
      controller do
        get :test, "/test" do
          verify do
            instance_eval(&local.verify_def)
          end

          connection.body = StringIO.new(Marshal.dump(params))
        end
      end
    }
  }

  include_examples "verification"
  include_examples "nested verification"
end

RSpec.describe "handling failed verification" do
  context "without a custom handler" do
    include_context "app"

    let(:app_def) {
      Proc.new {
        controller do
          verify :test do
            required :value
          end

          get :test, "/test"
        end
      }
    }

    it "automatically responds as a bad request" do
      expect(call("/test")[0]).to eq(400)
    end
  end

  context "with a custom handler" do
    include_context "app"

    let(:app_def) {
      Proc.new {
        controller do
          handle Pakyow::InvalidData, as: :not_found

          verify :test do
            required :value
          end

          get :test, "/test"
        end
      }
    }

    it "is possible to use a custom handler instead" do
      expect(call("/test")[0]).to eq(404)
    end
  end
end

RSpec.describe "setting allowed params" do
  include_context "app"
  include_context "verification helpers"

  context "verified in the controller" do
    let(:app_def) {
      Proc.new {
        controller do
          allow_params :value1

          verify :test do
            required :value2
          end

          get :test, "/test" do
            send params.to_json
          end
        end
      }
    }

    it "allows allowed params" do
      response(value1: "one", value2: "two").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2]).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end

  context "verified in the route" do
    let(:app_def) {
      Proc.new {
        controller do
          allow_params :value1

          get :test, "/test" do
            verify do
              required :value2
            end

            send params.to_json
          end
        end
      }
    }

    it "allows allowed params" do
      response(value1: "one", value2: "two").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2]).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end

  context "allow params is called twice" do
    let(:app_def) {
      Proc.new {
        controller do
          allow_params :value1
          allow_params :value2

          get :test, "/test" do
            verify do
            end

            send params.to_json
          end
        end
      }
    }

    it "allows all allowed params" do
      response(value1: "one", value2: "two").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2]).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end

  describe "inheriting allowed params" do
    let(:app_def) {
      Proc.new {
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
      }
    }

    it "inherits allowed params from a parent controller" do
      response(value1: "one", value2: "two").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2]).to eq('{"value1":"one","value2":"two"}')
      end
    end
  end
end

RSpec.describe "allowing resource ids" do
  include_context "app"
  include_context "verification helpers"

  let(:app_def) {
    Proc.new do
      resource :posts, "/posts" do
        show do
          verify do
          end

          send params.to_json
        end

        member do
          get :foo, "/foo" do
            verify do
            end

            send params.to_json
          end
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
  }

  it "allows top level resource ids" do
    call("/posts/1").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2]).to eq('{"id":"1"}')
    end
  end

  it "allows nested resource ids" do
    call("/posts/1/comments/2").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2]).to eq('{"post_id":"1","id":"2"}')
    end
  end

  it "allows nested member ids" do
    call("/posts/1/foo").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2]).to eq('{"post_id":"1"}')
    end
  end
end
