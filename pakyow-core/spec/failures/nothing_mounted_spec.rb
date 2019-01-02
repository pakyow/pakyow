RSpec.describe "running the environment when nothing is mounted" do
  it "fails, telling the user what's wrong" do
    expect {
      Pakyow.run
    }.to raise_error(RuntimeError) do |error|
      expect(error.to_s).to eq("can't run because no apps are mounted")
    end
  end
end
