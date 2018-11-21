RSpec.shared_examples :source_results do
  describe "returning results from a query" do
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

        context "fetched multiple times" do
          it "returns a data object" do
            posts = data.posts
            (2..10).to_a.sample.times do
              expect(posts.one).to be_instance_of(Pakyow::Data::Object)
            end
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

        context "fetched multiple times" do
          it "returns a data object" do
            posts = data.posts
            (2..10).to_a.sample.times do
              posts.to_a.each do |post|
                expect(post).to be_instance_of(Pakyow::Data::Object)
              end
            end
          end
        end
      end
    end

    describe "returning result count" do
      it "returns the count" do
        expect(data.posts.count).to eq(3)
      end

      it "does not fetch the results" do
        posts = data.posts.ordered
        posts.count

        expect(posts.source.instance_variable_get(:@results)).to be(nil)
      end
    end

    describe "enumerating over the result" do
      it "enumerates" do
        found = data.posts.find { |post|
          post[:id] == 1
        }

        expect(found).to be_instance_of(Pakyow::Data::Object)
        expect(found).to eq(data.posts.to_a.first)
      end
    end

    describe "calling an array method on the result" do
      it "succeeds" do
        found = data.posts.last
        expect(found).to be_instance_of(Pakyow::Data::Object)
        expect(found).to eq(data.posts.to_a.last)
      end
    end

    describe "invalidating fetched results" do
      context "results are fetched as a different type after the result has been returned" do
        before do
          data.posts.create(title: "foo")
        end

        let :posts do
          results = data.posts
          results.one
          results.as(as)
        end

        let :as do
          Class.new(Pakyow::Data::Object)
        end

        it "invalidates" do
          expect(posts.one).to be_instance_of(as)
        end
      end

      context "associated data is included after the result has been returned" do
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

            source :comments do
              primary_id

              belongs_to :post
            end
          end
        end

        before do
          data.comments.create(post: data.posts.create(title: "foo"))
        end

        let :comments do
          results = data.comments
          results.one
          results.including(:post)
        end

        it "invalidates" do
          expect(comments.one.post).to be_instance_of(Pakyow::Data::Object)
        end
      end
    end
  end
end
