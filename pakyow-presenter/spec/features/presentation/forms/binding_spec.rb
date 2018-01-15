RSpec.describe "binding values to a form via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form@post>
          <input@title type="text">
          <textarea@body></textarea>
          <input@published type="checkbox" value="true">
          <input@public type="checkbox" value="true">
          <input@public type="checkbox" value="false">
          <select@tag><option value="foo">Foo</option><option value="bar">Bar</option></select>
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post)
  end

  describe "binding an object to a form" do
    describe "binding a value to an input" do
      before do
        form.bind(title: "foo")
      end

      it "binds the value" do
        expect(form.find(:title).attrs[:value]).to eq("foo")
      end
    end

    describe "binding a value to a textarea" do
      before do
        form.bind(body: "foo")
      end

      it "binds the value" do
        expect(form.find(:body).text).to eq("foo")
      end
    end

    describe "binding a value to a checkbox" do
      context "bound value matches checkbox value" do
        before do
          form.bind(published: "true")
        end

        it "checks the checkbox" do
          expect(form.find(:published).attrs[:checked]).to be(true)
        end

        context "checkbox is already checked" do
          before do
            form.find(:published).attrs[:checked] = true
            form.bind(published: "false")
          end

          it "unchecks the checkbox" do
            expect(form.find(:published).attrs[:checked]).to be(false)
          end
        end
      end

      context "bound value does not match checkbox value" do
        context "checkbox is not already checked" do
          before do
            form.bind(published: "false")
          end

          it "unchecks the checkbox" do
            expect(form.find(:published).attrs[:checked]).to be(false)
          end
        end
      end
    end

    describe "binding a value to a radio button" do
      context "bound value matches one radio button value" do
        before do
          form.bind(public: "true")
        end

        it "checks the matching radio button" do
          expect(form.find_all(:public)[0].attrs[:checked]).to be(true)
        end

        it "unchecks the radio button that does not match" do
          expect(form.find_all(:public)[1].attrs[:checked]).to be(false)
        end

        context "radio buttons are already checked" do
          before do
            form.find_all(:public)[0].attrs[:checked] = true
            form.find_all(:public)[1].attrs[:checked] = true
            form.bind(public: "foo")
          end

          it "unchecks all radio buttons" do
            expect(form.find_all(:public)[0].attrs[:checked]).to be(false)
            expect(form.find_all(:public)[1].attrs[:checked]).to be(false)
          end
        end
      end

      context "bound value does not match any radio button values" do
        before do
          form.bind(public: "foo")
        end

        it "unchecks all radio buttons" do
          expect(form.find_all(:public)[0].attrs[:checked]).to be(false)
          expect(form.find_all(:public)[1].attrs[:checked]).to be(false)
        end
      end
    end

    describe "binding a value to a select field" do
      context "bound value matches one option value" do
        before do
          form.bind(tag: "bar")
        end

        it "selects the matching option" do
          expect(form.find(:tag).view.object.find_significant_nodes(:option)[1].attributes[:selected]).to eq("selected")
        end

        it "unselects the options that do not match" do
          expect(form.find(:tag).view.object.find_significant_nodes(:option)[0].attributes[:selected]).to eq(nil)
        end

        context "option is already selected" do
          before do
            form.find(:tag).view.object.find_significant_nodes(:option)[0].attributes[:selected] = "selected"
            form.bind(tag: "bar")
          end

          it "unselects the options that do not match" do
            expect(form.find(:tag).view.object.find_significant_nodes(:option)[0].attributes[:selected]).to eq(nil)
            expect(form.find(:tag).view.object.find_significant_nodes(:option)[1].attributes[:selected]).to eq("selected")
          end
        end
      end

      context "bound value does not match any option values" do
        before do
          form.bind(tag: "tfa")
        end

        it "unselects all options" do
          expect(form.find(:tag).view.object.find_significant_nodes(:option)[0].attributes[:selected]).to eq(nil)
          expect(form.find(:tag).view.object.find_significant_nodes(:option)[1].attributes[:selected]).to eq(nil)
        end
      end
    end
  end
end
