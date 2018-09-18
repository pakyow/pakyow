RSpec.describe "core aspects" do
  include_examples "testable app"

  # Helpers are sort of an unpublished aspect, because we load them outside of
  # the normal aspect flow. We do this so that published aspects inherit
  # helpers properly.
  #
  it "does not register helpers as an aspect" do
    expect(app.config.aspects).to_not include(:helpers)
  end
end
