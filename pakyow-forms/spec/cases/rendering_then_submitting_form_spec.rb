require_relative "./support/complete_app_context"

RSpec.describe "rendering then submitting a form" do
  include_context "complete app"

  it "removes the errors binding"

  context "form is submitted" do
    context "submitted data is valid" do
      it "calls the route in a normal way"
    end

    context "submitted data is invalid" do
      it "reroutes to the origin"
      it "presents errors for the invalid submission"
      it "presents the submitted data"

      context "app handles the invalid submission" do
        it "does not call the form submission handler"
      end
    end
  end

  context "form is submitted through ui" do
    context "submitted data is valid" do
      it "calls the route in a normal way"
    end

    context "submitted data is invalid" do
      it "pushes the error presentation"
      it "does not reroute"

      context "app handles the invalid submission" do
        it "does not call the form submission handler"
      end
    end
  end
end
