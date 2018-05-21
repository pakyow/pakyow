RSpec.shared_examples :source_results do
  describe "returning results from a query" do
    before do
      Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
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

          def ordered
            order(:id)
          end
        end
      end
    end

    before do
      data.posts.create(title: "foo")
      data.posts.create(title: "bar")
      data.posts.create(title: "baz")
    end

    describe "returning a single result" do
      describe "one" do
        context "query contains a single result" do
          it "returns a single result" do
            expect(data.posts.by_id(1).one[:title]).to eq("foo")
          end
        end

        context "query contains more than one result" do
          it "returns the first result" do
            expect(data.posts.ordered.one[:title]).to eq("foo")
          end
        end

        context "query contains no results" do
          it "returns nil" do
            data.posts.delete
            expect(data.posts.ordered.one).to be(nil)
          end
        end
      end
    end

    describe "returning multiple results" do
      describe "to_a" do
        it "returns multiple results" do
          expect(data.posts.ordered.to_a.count).to eq(3)
          expect(data.posts.ordered.to_a[0][:title]).to eq("foo")
          expect(data.posts.ordered.to_a[1][:title]).to eq("bar")
          expect(data.posts.ordered.to_a[2][:title]).to eq("baz")
        end
      end
    end

    describe "returning result count" do
      it "returns the count" do
        expect(data.posts.count).to eq(3)
      end
    end
  end
end
