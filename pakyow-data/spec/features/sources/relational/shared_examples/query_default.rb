RSpec.shared_examples :source_query_default do
  describe "defining a default source query" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after "configure" do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    context "query is referenced by name" do
      let :app_init do
        Proc.new do
          source :posts do
            primary_id
            attribute :title, :string

            query :ordered

            def ordered
              order(title: :asc)
            end
          end
        end
      end

      it "automatically applies the query" do
        data.posts.create(title: "2")
        data.posts.create(title: "3")
        data.posts.create(title: "1")

        expect(data.posts.to_a.map(&:title)).to eq(["1", "2", "3"])
      end
    end

    context "query is specified as a block that returns a dataset" do
      let :app_init do
        Proc.new do
          source :posts do
            primary_id
            attribute :title, :string

            query do
              order(title: :asc).exclude(title: "foo")
            end
          end
        end
      end

      it "automatically applies the query" do
        data.posts.create(title: "2")
        data.posts.create(title: "3")
        data.posts.create(title: "foo")
        data.posts.create(title: "1")

        expect(data.posts.to_a.map(&:title)).to eq(["1", "2", "3"])
      end
    end

    context "query is specified as a block that returns a source" do
      let :app_init do
        Proc.new do
          source :posts do
            primary_id
            attribute :title, :string

            query do
              ordered.without_foo
            end

            def ordered
              order(title: :asc)
            end

            def without_foo
              exclude(title: "foo")
            end
          end
        end
      end

      it "automatically applies the query" do
        data.posts.create(title: "2")
        data.posts.create(title: "3")
        data.posts.create(title: "foo")
        data.posts.create(title: "1")

        expect(data.posts.to_a.map(&:title)).to eq(["1", "2", "3"])
      end
    end

    context "query includes data" do
      let :app_init do
        Proc.new do
          source :posts do
            primary_id
            attribute :title, :string

            has_many :comments

            query do
              including(:comments)
            end
          end

          source :comments do
            primary_id
          end
        end
      end

      it "automatically applies the query" do
        data.posts.create(title: "2", comments: data.comments.create)
        expect(data.posts.one.comments.first).to be_instance_of(Pakyow::Data::Object)
      end
    end
  end
end
