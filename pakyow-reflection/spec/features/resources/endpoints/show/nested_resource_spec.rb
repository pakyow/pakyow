RSpec.describe "reflected resource show endpoint" do
  context "resource is nested in another resource" do
    context "requested object belongs to the parent" do
      it "presents the object"
    end

    context "requested object does not belong to the parent" do
      it "404s"
    end
  end
end
