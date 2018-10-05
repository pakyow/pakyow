RSpec.describe "initially rendering a form with an error component" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$form_app_boilerplate)
    end
  end

  it "removes the errors binding" do
    expect(call("/")[2].body.read).to_not include('<li data-b="error"')
  end
end
