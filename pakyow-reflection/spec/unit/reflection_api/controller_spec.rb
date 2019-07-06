RSpec.describe "the public reflection api available to controllers" do
  describe "#with_reflected_action" do
    context "reflected action is available" do
      it "yields the reflected action"
    end

    context "reflected action is missing" do
      it "404s"
    end
  end

  describe "#with_reflected_endpoints" do
    context "reflected endpoints is available" do
      it "yields the reflected endpoints"
    end

    context "reflected endpoints is missing" do
      it "404s"
    end
  end

  describe "#reflective_expose" do
    it "exposes data for the reflected endpoints"
  end

  describe "#verify_reflected_form" do
    context "data is submitted outside of a form" do
      it "fails"
    end

    context "invalid data is submitted from a form" do
      it "raises an invalid data error"
    end

    context "valid data is submitted from a form" do
      it "creates the object"
    end

    context "reflected scope is missing" do
      it "does not fail"
    end

    describe "validity" do
      context "reflected attribute is required" do
        it "requires the attribute"
      end

      context "reflected attribute is not required" do
        it "does not require the attribute"
      end
    end
  end

  describe "#perform_reflected_action" do
    describe "create endpoint" do
      it "creates"
    end

    describe "update endpoint" do
      it "updates"
    end

    describe "delete endpoint" do
      it "deletes"
    end

    context "reflected scope is missing" do
      it "does not fail"
    end
  end

  describe "#redirect_to_reflected_destination" do
    context "destination exists" do
      it "redirects"
    end

    context "destination is missing" do
      it "does not redirect"
    end
  end

  describe "#reflected_destination" do
    context "called from a form submission" do
      context "form origin is included" do
        context "object is available" do
          context "show route exists for the object" do
            it "redirects to show"
          end

          context "list route exists for the object" do
            it "redirects to list"
          end

          context "show and list routes exists for the object" do
            it "redirects to show"
          end

          context "neither show nor list route exists for the object" do
            it "redirects to the form origin"
          end
        end

        context "object is not available" do
          it "redirects to the form origin"
        end
      end

      context "form origin is not included" do
        it "returns nil"
      end
    end

    context "called outside a form submission" do
      it "returns nil"
    end

    context "reflected scope is missing" do
      it "does not fail"
    end
  end
end
