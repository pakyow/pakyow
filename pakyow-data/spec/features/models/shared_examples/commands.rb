RSpec.shared_examples :model_commands do
  describe "built-in model commands" do
    before do
      Pakyow.config.connections.sql[:default] = connection_string
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        model :posts do
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
        expect(data.posts.create({})).to be_instance_of(Hash)
      end
    end

    describe "update" do
      before do
        data.posts.create(title: "foo")
        data.posts.create(title: "bar")
        @result = data.posts.update(title: "baz")
      end

      it "updates all matching records" do
        expect(data.posts.count).to eq(2)
        expect(data.posts.all[0][:title]).to eq("baz")
        expect(data.posts.all[1][:title]).to eq("baz")
      end

      it "returns the updated results" do
        expect(@result).to be_instance_of(Array)
        expect(@result.count).to eq(2)
        expect(@result[0][:title]).to eq("baz")
        expect(@result[1][:title]).to eq("baz")
      end
    end

    describe "delete" do
      before do
        data.posts.create(title: "foo")
        data.posts.create(title: "bar")
        @result = data.posts.delete
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

  describe "custom model commands" do
    it "needs to be defined"
  end
end
