RSpec.shared_examples :model_queries do
  describe "built-in model queries" do
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
        end
      end
    end

    describe "by_attribute queries" do
      it "defines a query for each attribute" do
        post = data.posts.create(title: "foo")
        expect(data.posts.by_id(1).count).to eq(1)
        expect(data.posts.by_title("foo").count).to eq(1)
        expect(data.posts.by_title("bar").count).to eq(0)
      end
    end
  end

  describe "custom model queries" do
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
            def title_is_foo
              where(title: "foo")
            end
          end
        end
      end
    end

    it "exposes the query" do
      post = data.posts.create(title: "foo")
      post = data.posts.create(title: "bar")
      expect(data.posts.title_is_foo.count).to eq(1)
    end
  end
end
