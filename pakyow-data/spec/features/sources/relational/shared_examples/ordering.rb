RSpec.shared_examples :source_ordering do
  describe "ordering datasets" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after "configure" do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_init do
      Proc.new do
        source :posts do
          attribute :title
          attribute :body
        end
      end
    end

    before do
      data.posts.create(title: "b", body: "b")
      data.posts.create(title: "c", body: "c")
      data.posts.create(title: "a", body: "a")
      data.posts.create(title: "a", body: "z")
    end

    it "orders by a field" do
      expect(data.posts.order(:title).one.title).to eq("a")
    end

    it "orders by multiple fields" do
      expect(data.posts.order(:title, :body).one.id).to eq(3)
    end

    it "orders by a field in a direction" do
      expect(data.posts.order(title: :desc).one.id).to eq(2)
    end

    it "orders by a multiple fields in a direction" do
      expect(data.posts.order(title: :asc, body: :desc).one.id).to eq(4)
    end

    it "orders by a multiple fields in a direction specified as an array" do
      expect(data.posts.order([:title, :asc], [:body, :desc]).one.id).to eq(4)
    end

    it "orders by complex conditions" do
      expect(data.posts.order({ title: :asc }, [:body, :desc], :id).one.id).to eq(4)
    end
  end
end
