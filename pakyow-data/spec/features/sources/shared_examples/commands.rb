RSpec.shared_examples :source_commands do
  describe "built-in source commands" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          attribute :title, :string
        end
      end
    end

    describe "create" do
      it "creates a record" do
        data.posts.create({})
        expect(data.posts.count).to eq(1)
      end

      it "returns a single result" do
        expect(data.posts.create({}).one).to be_instance_of(Pakyow::Data::Object)
      end

      context "value is nil" do
        it "creates with the nil value" do
          expect(data.posts.create(title: nil).one).to be_instance_of(Pakyow::Data::Object)
        end
      end
    end

    describe "update" do
      before do
        data.posts.create(title: "foo")
        data.posts.create(title: "bar")
        @result = data.posts.update(title: "baz").to_a
      end

      it "updates all matching records" do
        expect(data.posts.count).to eq(2)
        expect(data.posts.to_a[0][:title]).to eq("baz")
        expect(data.posts.to_a[1][:title]).to eq("baz")
      end

      it "returns the updated results" do
        expect(@result).to be_instance_of(Array)
        expect(@result.count).to eq(2)
        expect(@result[0][:title]).to eq("baz")
        expect(@result[1][:title]).to eq("baz")
      end

      context "value is nil" do
        it "updates with the nil value" do
          expect(data.posts.count).to eq(2)
          expect(data.posts.to_a[0][:title]).to eq("baz")
          expect(data.posts.to_a[1][:title]).to eq("baz")

          data.posts.update(title: nil).to_a
          expect(data.posts.to_a[0][:title]).to eq(nil)
          expect(data.posts.to_a[1][:title]).to eq(nil)
        end
      end

      context "updating with no values" do
        it "does not fail" do
          expect {
            data.posts.update({})
          }.not_to raise_error
        end

        it "returns the results" do
          result = data.posts.update({}).to_a
          expect(result).to be_instance_of(Array)
          expect(result.count).to eq(2)
        end
      end
    end

    describe "delete" do
      before do
        data.posts.create(title: "foo")
        data.posts.create(title: "bar")
        @result = data.posts.delete.to_a
      end

      it "deletes all matching records" do
        expect(data.posts.count).to eq(0)
      end

      it "returns multiple results" do
        expect(@result).to be_instance_of(Array)
        expect(@result.count).to eq(2)
        expect(@result[0][:title]).to eq("foo")
        expect(@result[1][:title]).to eq("bar")
      end
    end
  end

  describe "custom source commands" do
    it "needs to be defined"
  end
end
