RSpec.describe "view titles via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view, presentables: presentables)
  end

  let :presentables do
    {}
  end

  before do
    presenter.call(presenter)
  end

  context "title contained in front matter" do
    let :view do
      Pakyow::Presenter::View.new("<head><title></title></head>", info: { "title" => "hi" })
    end

    it "sets the value" do
      expect(presenter.title).to eq("hi")
    end

    context "title contains dynamic values" do
      let :view do
        Pakyow::Presenter::View.new("<head><title></title></head>", info: { "title" => "My Site | {greeting} {user.name}" })
      end

      context "presentables exist" do
        let :presentables do
          {
            greeting: "hi",
            user: {
              name: "bob"
            }
          }
        end

        it "sets the value" do
          expect(presenter.title).to eq("My Site | hi bob")
        end
      end

      context "some presentables exist" do
        let :presentables do
          {
            greeting: "hi",
          }
        end

        it "sets a partial value" do
          expect(presenter.title).to eq("My Site | hi ")
        end
      end

      context "no presentables exist" do
        it "sets a partial value" do
          expect(presenter.title).to eq("My Site |  ")
        end
      end
    end
  end

  describe "setting" do
    context "title node exists" do
      let :view do
        Pakyow::Presenter::View.new("<head><title></title></head>")
      end

      it "sets the value" do
        presenter.title = "foo"
        expect(presenter.to_s).to eq("<head><title>foo</title></head>")
      end
    end

    context "title node does not exist" do
      let :view do
        Pakyow::Presenter::View.new("<head></head>")
      end

      it "inserts a title node and sets the value" do
        presenter.title = "foo"
        expect(presenter.to_s).to eq("<head><title>foo</title></head>")
      end
    end
  end

  describe "getting" do
    context "title node exists" do
      let :view do
        Pakyow::Presenter::View.new("<head><title>foo</title></head>")
      end

      it "gets the value" do
        expect(presenter.title).to eq("foo")
      end
    end

    context "title node does not exist" do
      let :view do
        Pakyow::Presenter::View.new("<head></head>")
      end

      it "returns nil" do
        expect(presenter.title).to eq(nil)
      end
    end
  end
end
