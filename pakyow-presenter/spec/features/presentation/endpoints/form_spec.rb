RSpec.describe "presenting a view that defines a form endpoint" do
  include_context "app"

  context "form node defines an endpoint" do
    context "endpoint is get" do
      it "sets the action"
      it "sets the method"
    end

    context "endpoint is post" do
      it "sets the action"
      it "sets the method"
    end

    context "endpoint is not get or post" do
      it "sets the action"
      it "sets the method"
      it "creates the method input"
    end

    context "endpoint does not exist" do
      it "does nothing"
    end

    context "endpoint node is within a binding" do
      it "does not set the href automatically"

      context "binding is bound to" do
        it "sets the href"

        context "endpoint is current" do
          it "adds an active class"
        end

        context "endpoint does not exist" do
          it "does nothing"
        end
      end
    end
  end

  context "form node defines a contextual endpoint" do
    it "builds the action using request params as context"

    context "endpoint node is within a binding" do
      it "builds the action using binding as context"
    end
  end
end
