RSpec.describe "email validation" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      controller do
        verify :test do
          required :value do
            validate :unique, source: :posts
          end
        end

        get :test, "/test"
      end

      source :posts do
        attribute :value
      end
    end
  end

  before do
    Pakyow.apps.first.data.posts.create(value: "foo")
  end

  context "value is not unique" do
    it "responds 400" do
      expect(call("/test", params: { value: "foo" })[0]).to eq(400)
    end
  end

  context "value is unique" do
    it "responds 200" do
      expect(call("/test", params: { value: "bar" })[0]).to eq(200)
    end
  end

  context "updating" do
    let :app_def do
      Proc.new do
        controller do
          get :test, "/test/:id" do
            result = data.posts.by_id(params[:id]).one

            verify do
              required :value do
                validate :unique, source: :posts, updating: result
              end
            end
          end
        end

        source :posts do
          attribute :value
        end
      end
    end

    before do
      Pakyow.apps.first.data.posts.create(value: "bar")
    end

    context "value is not unique because it's the value of the object being updated" do
      it "responds 200" do
        expect(call("/test/1", params: { value: "foo" })[0]).to eq(200)
      end
    end

    context "value is not unique because it's a value on an object not being updated" do
      it "responds 400" do
        expect(call("/test/2", params: { value: "foo" })[0]).to eq(400)
      end
    end

    context "value is unique" do
      it "responds 200" do
        expect(call("/test/1", params: { value: "baz" })[0]).to eq(200)
      end
    end

    context "value that is being updated is not a result" do
      let :app_def do
        Proc.new do
          controller do
            get :test, "/test/:id" do
              result = data.posts.by_id(params[:id])

              verify do
                required :value do
                  validate :unique, source: :posts, updating: result
                end
              end
            end
          end

          source :posts do
            attribute :value
          end
        end
      end

      let :allow_request_failures do
        true
      end

      it "raises an error" do
        expect(call("/test/1", params: { value: "foo" })[0]).to eq(500)
        expect(connection.error).to be_instance_of(ArgumentError)
        expect(connection.error.to_s).to eq("Expected `Pakyow::Data::Proxy' to be a `Pakyow::Data::Result'")
      end
    end
  end
end
