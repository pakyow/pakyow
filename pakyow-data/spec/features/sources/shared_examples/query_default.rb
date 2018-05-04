RSpec.shared_examples :source_query_default do
  describe "defining a default source query" do
    before do
      Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    context "query is referenced by name" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            attribute :title, :string

            query :ordered

            def ordered
              order { title.asc }
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

    context "query is specified as a block" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            attribute :title, :string

            query {
              ordered.without_foo
            }

            def ordered
              order { title.asc }
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
  end
end
