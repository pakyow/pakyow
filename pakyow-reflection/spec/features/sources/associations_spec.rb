RSpec.describe "reflected associations" do
  include_context "reflectable app"

  let :posts do
    Pakyow.apps.first.state(:source)[0]
  end

  let :comments do
    Pakyow.apps.first.state(:source)[1]
  end

  let :frontend_test_case do
    "sources"
  end

  it "defines a has_many association for each child" do
    expect(posts.associations[:has_many].count).to be(1)
    expect(posts.associations[:has_many][0].associated_source_name).to be(:comments)

    expect(comments.associations[:belongs_to].count).to be(1)
    expect(comments.associations[:belongs_to][0].associated_source_name).to be(:posts)
  end

  it "sets up the association to delete dependents"

  context "source is already defined" do
    let :reflected_app_init do
      Proc.new do
        source :posts, timestamps: false do
          primary_key :id
          attribute :id, type: :string
        end
      end
    end

    context "reflected association does not exist" do
      it "extends the existing source with the reflected association" do
        expect(posts.associations[:has_many].count).to be(1)
        expect(posts.associations[:has_many][0].associated_source_name).to be(:comments)
      end
    end

    context "existing source defines a reflected association" do
      let :reflected_app_init do
        Proc.new do
          source :posts do
            has_many :comments, query: :foo
          end
        end
      end

      it "does not override the existing association" do
        expect(posts.associations[:has_many].count).to be(1)
        expect(posts.associations[:has_many][0].query).to be(:foo)
      end
    end
  end
end
