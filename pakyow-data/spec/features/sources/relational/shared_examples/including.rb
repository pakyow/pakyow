RSpec.shared_examples :source_including do
  describe "including associations" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_init do
      Proc.new do
        source :posts do
          primary_id
          timestamps
          attribute :title
          has_many :comments
          has_one :author, source: :users

          query do
            order { id.asc }
          end
        end

        source :comments do
          primary_id
          timestamps
          attribute :body
          has_one :author, source: :users

          query do
            order { id.asc }
          end
        end

        source :users do
          primary_id
          timestamps
          attribute :name
        end

        object :special do
        end
      end
    end

    describe "including multiple associations" do
      before do
        data.posts.create(
          title: "post 1",
          author: data.users.create(
            name: "post 1 author"
          ),
          comments: data.comments.create(
            body: "post 1 comment 1",
            author: data.users.create(
              name: "post 1 comment 1 author"
            )
          )
        )
      end

      let :results do
        data.posts.including(:author).including(:comments)
      end

      it "includes the results from all associations" do
        expect(results.count).to eq(1)
        expect(results.first.title).to eq("post 1")
        expect(results.first.author.name).to eq("post 1 author")
        expect(results.first.comments.count).to eq(1)
        expect(results.first.comments.first.body).to eq("post 1 comment 1")
      end
    end

    describe "including an association through an association" do
      before do
        data.posts.create(
          title: "post 1",
          author: data.users.create(
            name: "post 1 author"
          ),
          comments: data.comments.create(
            body: "post 1 comment 1",
            author: data.users.create(
              name: "post 1 comment 1 author"
            )
          )
        )
      end

      let :results do
        data.posts.including(:comments) {
          including(:author)
        }
      end

      it "includes the results from all associations" do
        expect(results.count).to eq(1)
        expect(results.first.title).to eq("post 1")
        expect(results.first.comments.count).to eq(1)
        expect(results.first.comments.first.body).to eq("post 1 comment 1")
        expect(results.first.comments.first.author.name).to eq("post 1 comment 1 author")
      end
    end

    describe "included data" do
      before do
        data.posts.create(
          title: "post 1",
          author: data.users.create(
            name: "post 1 author"
          )
        )
      end

      let :included_data do
        data.posts.including(:author).one.author
      end

      shared_examples :included_data_values do
        describe "the data object" do
          it "includes the correct values" do
            expect(included_data.id).to eq(1)
            expect(included_data.name).to eq("post 1 author")
          end
        end
      end

      include_examples :included_data_values

      it "is a data object" do
        expect(included_data).to be_instance_of(Pakyow::Data::Object)
      end

      context "type is specified" do
        let :included_data do
          data.posts.including(:author) {
            as(:special)
          }.one.author
        end

        it "is of the specified type" do
          expect(included_data).to be_instance_of(Test::Objects::Special)
        end

        include_examples :included_data_values
      end
    end

    describe "with_association methods" do
      before do
        data.posts.create(
          title: "post 1",
          author: data.users.create(
            name: "post 1 author"
          ),
          comments: data.comments.create(
            body: "post 1 comment 1",
            author: data.users.create(
              name: "post 1 comment 1 author"
            )
          )
        )
      end

      let :results do
        data.posts.with_author
      end

      it "defines a method for each association" do
        expect(results.count).to eq(1)
        expect(results.first.title).to eq("post 1")
        expect(results.first.author.name).to eq("post 1 author")
      end
    end
  end
end
