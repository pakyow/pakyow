RSpec.shared_examples :model_results do
  describe "returning results from a query" do
    before do
      Pakyow.config.data.connections.sql[:default] = connection_string
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :post do
          primary_id
          attribute :title, :string

          queries do
            def ordered
              order(:id)
            end
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
          it "raises an error" do
            expect { data.posts.one }.to raise_error(ROM::TupleCountMismatchError)
          end
        end
      end

      describe "first" do
        it "returns the first result" do
          expect(data.posts.ordered.first[:title]).to eq("foo")
        end
      end

      describe "last" do
        it "returns the last result" do
          expect(data.posts.ordered.last[:title]).to eq("baz")
        end
      end
    end

    describe "returning multiple results" do
      describe "all" do
        it "returns multiple results" do
          expect(data.posts.ordered.all.count).to eq(3)
          expect(data.posts.ordered.all[0][:title]).to eq("foo")
          expect(data.posts.ordered.all[1][:title]).to eq("bar")
          expect(data.posts.ordered.all[2][:title]).to eq("baz")
        end
      end

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
