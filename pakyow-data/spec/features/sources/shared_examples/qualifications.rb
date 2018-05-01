RSpec.shared_examples :source_qualifications do
  describe "qualifications for by_attribute queries" do
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
        end
      end
    end

    it "defines a qualification for each query" do
      expect(data.posts.source.class.qualifications(:by_id)).to eq(id: :__arg0__)
      expect(data.posts.source.class.qualifications(:by_title)).to eq(title: :__arg0__)
    end
  end

  describe "qualifications for custom source queries" do
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

          subscribe :title_is_foo, title: "foo"
          def title_is_foo
            where(title: "foo")
          end
        end
      end
    end

    it "defines the qualification" do
      expect(data.posts.source.class.qualifications(:title_is_foo)).to eq(title: "foo")
    end
  end
end
