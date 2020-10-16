RSpec.shared_examples :source_results do
  describe "returning results from a query" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after "configure" do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_def do
      Proc.new do
        source :posts do
          primary_id
          attribute :title, :string

          def ordered
            order(:id)
          end
        end

        object :special do
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
            expect(data.posts.by_id(1).one).to be_instance_of(Pakyow::Data::Result)
            expect(data.posts.by_id(1).one.__getobj__).to be_instance_of(Pakyow::Data::Object)
            expect(data.posts.by_id(1).one[:title]).to eq("foo")
          end
        end

        context "query contains more than one result" do
          it "returns the first result" do
            expect(data.posts.ordered.one).to be_instance_of(Pakyow::Data::Result)
            expect(data.posts.ordered.one.__getobj__).to be_instance_of(Pakyow::Data::Object)
            expect(data.posts.ordered.one[:title]).to eq("foo")
          end
        end

        context "query contains no results" do
          before do
            data.posts.delete
          end

          it "returns nil wrapped in a result object" do
            expect(data.posts.ordered.one).to be_instance_of(Pakyow::Data::Result)
          end

          describe "the wrapped result" do
            it "responds correctly to nil?" do
              expect(data.posts.ordered.one.nil?).to be(true)
            end
          end
        end

        context "fetched multiple times" do
          it "returns a data object" do
            posts = data.posts
            (2..10).to_a.sample.times do
              expect(posts.one).to be_instance_of(Pakyow::Data::Result)
              expect(posts.one.__getobj__).to be_instance_of(Pakyow::Data::Object)
            end
          end
        end

        context "fetching as an object" do
          it "returns the proper object" do
            expect(data.posts.by_id(1).as(:special).one).to be_instance_of(Pakyow::Data::Result)
            expect(data.posts.by_id(1).as(:special).one.__getobj__).to be_instance_of(Test::Objects::Special)
          end
        end
      end
    end

    describe "returning multiple results" do
      shared_examples "multiple" do
        it "returns multiple results" do
          results = data.posts.ordered.public_send(method)
          expect(results.count).to eq(3)

          results.each do |post|
            expect(post).to be_instance_of(Pakyow::Data::Object)
          end

          expect(results[0][:title]).to eq("foo")
          expect(results[1][:title]).to eq("bar")
          expect(results[2][:title]).to eq("baz")
        end

        it "wraps the array in a result object" do
          results = data.posts.ordered.public_send(method)
          expect(results).to be_instance_of(Pakyow::Data::Result)
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

        context "fetching as an object" do
          it "returns the proper object" do
            results = data.posts.ordered.as(:special).to_a
            expect(results.count).to eq(3)

            results.each do |post|
              expect(post).to be_instance_of(Test::Objects::Special)
            end
          end
        end
      end

      describe "to_a" do
        it_behaves_like "multiple" do
          let :method do
            :to_a
          end
        end
      end

      describe "all" do
        it_behaves_like "multiple" do
          let :method do
            :all
          end
        end
      end
    end

    describe "returning multiple results after fetching a single result" do
      let :results do
        results = query
        results.one
        results.all
      end

      let :query do
        data.posts
      end

      it "returns multiple results" do
        expect(results.count).to eq(3)
      end

      context "has_many association is included" do
        let :app_def do
          Proc.new do
            source :posts do
              has_many :comments

              attribute :title, :string
            end

            source :comments do
            end
          end
        end

        let :query do
          data.posts.including(:comments)
        end

        before do
          data.comments.create(post: data.posts.first)
        end

        it "includes the associated data" do
          expect(results[0].comments.count).to eq(1)
        end
      end

      context "has_many :through association is included" do
        let :app_def do
          Proc.new do
            source :posts do
              has_many :comments, through: :post_comments

              attribute :title, :string
            end

            source :post_comments do
              belongs_to :post
              belongs_to :comment
            end

            source :comments do
            end
          end
        end

        let :query do
          data.posts.including(:comments)
        end

        before do
          data.post_comments.create(
            post: data.posts.one,
            comment: data.comments.create
          )
        end

        it "includes the associated data" do
          expect(results[0].comments.count).to eq(1)
        end
      end
    end

    describe "returning result count" do
      it "returns the count" do
        expect(data.posts.count).to eq(3)
      end

      it "wraps the value in a result object" do
        expect(data.posts.count).to be_instance_of(Pakyow::Data::Result)
      end

      it "does not fetch the results" do
        posts = data.posts.ordered
        posts.count

        expect(posts.source.instance_variable_defined?(:@results)).to be(false)
      end
    end

    describe "enumerating over the result" do
      it "enumerates" do
        found = data.posts.find { |post|
          post[:id] == 1
        }

        expect(found).to be_instance_of(Pakyow::Data::Result)
        expect(found.__getobj__).to be_instance_of(Pakyow::Data::Object)
        expect(found).to eq(data.posts.to_a.first)
      end
    end

    describe "calling an array method on the result" do
      it "succeeds" do
        found = data.posts.last
        expect(found).to be_instance_of(Pakyow::Data::Result)
        expect(found.__getobj__).to be_instance_of(Pakyow::Data::Object)
        expect(found).to eq(data.posts.to_a.last)
      end

      it "wraps the value in a result object" do
        expect(data.posts.last).to be_instance_of(Pakyow::Data::Result)
      end
    end

    describe "calling a method that returns a boolean value" do
      it "returns the raw result" do
        expect(data.posts.any? { |post| post.title == "42" }).to be(false)
      end
    end

    describe "invalidating fetched results" do
      it "invalidates through reload"

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
          expect(posts.one.__getobj__).to be_instance_of(as)
        end
      end

      context "associated data is included after the result has been returned" do
        let :app_def do
          Proc.new do
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

    describe "as_object methods" do
      it "defines a method for each object" do
        expect(data.posts.by_id(1).as_special.one).to be_instance_of(Pakyow::Data::Result)
        expect(data.posts.by_id(1).as_special.one.__getobj__).to be_instance_of(Test::Objects::Special)
      end
    end

    describe "partial results" do
      let :app_def do
        super_def = super()

        Proc.new do
          class_eval(&super_def)

          source :other_posts do
            table :posts

            primary_id
          end
        end
      end

      before do
        data.posts.create(title: "foo")
      end

      let(:values) {
        data.other_posts.first.to_h
      }

      it "does not include columns not defined as attributes" do
        expect(values.keys).to eq(%w(id created_at updated_at))
      end

      context "including partial results" do
        let :app_def do
          super_def = super()

          Proc.new do
            class_eval(&super_def)

            source :comments do
              primary_id
              belongs_to :post
              belongs_to :other_post
            end
          end
        end

        before do
          data.comments.create(other_post_id: data.posts.first.id)
        end

        let(:values) {
          data.comments.including(:other_post).first[:other_post].to_h
        }

        it "does not include columns not defined as attributes" do
          expect(values.keys).to eq(%w(id created_at updated_at))
        end
      end
    end
  end
end
