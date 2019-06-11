RSpec.describe "reflected attributes" do
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

  it "has the correct number of attributes" do
    expect(posts.attributes.count).to eq(5)
    expect(comments.attributes.count).to eq(5)
  end

  it "defines an attribute for each discovered attribute" do
    expect(posts.attributes.keys).to include(:title)
    expect(posts.attributes[:title].primitive).to be(String)

    expect(posts.attributes.keys).to include(:body)
    expect(posts.attributes[:body].primitive).to be(String)

    expect(comments.attributes.keys).to include(:body)
    expect(comments.attributes[:body].primitive).to be(String)
  end

  it "defines a primary id by default" do
    expect(posts.attributes.keys).to include(:id)
    expect(posts.attributes[:id].primitive).to be(Integer)
    expect(posts.primary_key_field).to be(:id)

    expect(comments.attributes.keys).to include(:id)
    expect(comments.attributes[:id].primitive).to be(Integer)
    expect(comments.primary_key_field).to be(:id)
  end

  it "defines timestamps by default" do
    expect(posts.attributes.keys).to include(:created_at)
    expect(posts.attributes[:created_at].primitive).to be(DateTime)

    expect(posts.attributes.keys).to include(:updated_at)
    expect(posts.attributes[:updated_at].primitive).to be(DateTime)

    expect(comments.attributes.keys).to include(:created_at)
    expect(comments.attributes[:created_at].primitive).to be(DateTime)

    expect(comments.attributes.keys).to include(:updated_at)
    expect(comments.attributes[:updated_at].primitive).to be(DateTime)
  end

  it "defines attributes with the correct types"

  context "source is already defined" do
    let :reflected_app_def do
      Proc.new do
        source :posts, timestamps: false do
          primary_key :id
          attribute :id, type: :string
        end
      end
    end

    it "does not override the existing primary id" do
      expect(posts.attributes[:id].meta[:type]).to eq(:string)
    end

    it "does not add timestamps" do
      expect(posts.attributes.keys).not_to include(:created_at)
      expect(posts.attributes.keys).not_to include(:updated_at)
    end

    context "reflected attribute does not exist" do
      it "extends the existing source with the reflected attribute" do
        expect(posts.attributes.keys).to include(:body)
        expect(posts.attributes[:body].primitive).to be(String)
      end
    end

    context "existing source defines a reflected attribute" do
      let :reflected_app_def do
        Proc.new do
          source :posts do
            attribute :title, :decimal
          end
        end
      end

      it "does not override the existing attribute" do
        expect(posts.attributes.keys).to include(:title)
        expect(posts.attributes[:title].primitive).to be(BigDecimal)
      end
    end
  end
end
