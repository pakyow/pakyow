require "pakyow/support/safe_string"

RSpec.describe Pakyow::Support::SafeString do
  let :instance do
    described_class.new(String.new("foo"))
  end

  it "quacks like a string" do
    expect(instance.is_a?(String)).to be(true)
  end

  it "freezes the string on initialization" do
    expect {
      instance.gsub!("foo", "<script>alert('hacked')</script>")
    }.to raise_error(FrozenError)
  end
end

RSpec.describe Pakyow::Support::SafeStringHelpers do
  shared_examples :helpers do
    describe "ensure_html_safety" do
      context "passed an unsafe string" do
        it "calls html_escape and returns the safe string" do
          string = String.new("<script>alert('hacked')</script>")
          expect(context).to receive(:html_escape).with(string).and_call_original

          return_value = context.ensure_html_safety(string)
          expect(return_value).to be_instance_of(Pakyow::Support::SafeString)
          expect(return_value).to eq("&lt;script&gt;alert(&#39;hacked&#39;)&lt;/script&gt;")
        end
      end

      context "passed a safe string" do
        it "returns the safe string" do
          string = Pakyow::Support::SafeString.new("<script>alert('safe')</script>")
          expect(context).not_to receive(:html_escape)

          return_value = context.ensure_html_safety(string)
          expect(return_value).to be_instance_of(Pakyow::Support::SafeString)
          expect(return_value).to eq(string)
        end
      end
    end

    describe "html_safe?" do
      context "passed an unsafe string" do
        it "returns false" do
          expect(context.html_safe?("foo")).to be(false)
        end
      end

      context "passed a safe string" do
        it "returns true" do
          expect(context.html_safe?(Pakyow::Support::SafeString.new("foo"))).to be(true)
        end
      end
    end

    describe "html_safe" do
      context "passed an unsafe string" do
        it "returns a safe version of the string" do
          string = String.new("<script>alert('safe')</script>")
          expect(context.html_safe(string)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.html_safe(string)).to eq(string)
        end
      end

      context "passed a safe string" do
        it "returns the original string" do
          string = Pakyow::Support::SafeString.new("<script>alert('safe')</script>")
          expect(context.html_safe(string)).to be(string)
        end
      end
    end

    describe "html_escape" do
      context "passed an unsafe string" do
        it "returns a safe, escaped version of the string" do
          string = String.new("<script>alert('hacked')</script>")
          expect(context.html_escape(string)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.html_escape(string)).to eq("&lt;script&gt;alert(&#39;hacked&#39;)&lt;/script&gt;")
        end
      end

      context "passed a safe string" do
        it "returns a safe, escaped version of the string" do
          string = Pakyow::Support::SafeString.new("<script>alert('safe')</script>")
          expect(context.html_escape(string)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.html_escape(string)).to eq("&lt;script&gt;alert(&#39;safe&#39;)&lt;/script&gt;")
        end
      end

      context "passed something other than a string" do
        it "returns a safe, escaped, string version of the object" do
          object = nil
          expect(context.html_escape(object)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.html_escape(object)).to eq("")
        end
      end
    end

    describe "strip_tags" do
      context "passed an unsafe string" do
        it "returns a safe, stripped version of the string" do
          string = String.new("foo<script>alert('hacked')</script>bar")
          expect(context.strip_tags(string)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.strip_tags(string)).to eq("fooalert('hacked')bar")
        end
      end

      context "passed a safe string" do
        it "returns a safe, stripped version of the string" do
          string = Pakyow::Support::SafeString.new("foo<script>alert('safe')</script>bar")
          expect(context.strip_tags(string)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.strip_tags(string)).to eq("fooalert('safe')bar")
        end
      end

      context "passed something other than a string" do
        it "returns a safe, stripped, string version of the object" do
          object = nil
          expect(context.strip_tags(object)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.strip_tags(object)).to eq("")
        end
      end
    end

    describe "sanitize" do
      context "passed an unsafe string" do
        it "returns a safe, sanitized version of the string, leaving `tags` intact" do
          string = String.new("<strong>foo</strong><script>alert('hacked')</script>")
          expect(context.sanitize(string, tags: [:strong])).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.sanitize(string, tags: [:strong])).to eq("<strong>foo</strong>alert('hacked')")
        end
      end

      context "passed a safe string" do
        it "returns a safe, sanitized version of the string, leaving `tags` intact" do
          string = String.new("<strong>foo</strong><script>alert('safe')</script>")
          expect(context.sanitize(string, tags: [:strong])).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.sanitize(string, tags: [:strong])).to eq("<strong>foo</strong>alert('safe')")
        end
      end

      context "passed something other than a string" do
        it "returns a safe, sanitized, string version of the object" do
          object = nil
          expect(context.sanitize(object)).to be_instance_of(Pakyow::Support::SafeString)
          expect(context.sanitize(object)).to eq("")
        end
      end
    end
  end

  context "included in an object" do
    let :object do
      Class.new do
        include Pakyow::Support::SafeStringHelpers
      end
    end

    let :context do
      object.new
    end

    include_examples :helpers
  end

  context "used standalone" do
    let :context do
      Pakyow::Support::SafeStringHelpers
    end

    include_examples :helpers
  end
end
