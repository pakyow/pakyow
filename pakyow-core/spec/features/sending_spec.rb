RSpec.describe "sending data" do
  include_context "testable app"

  context "when sending a file" do
    def define
      Pakyow::App.define do
        router do
          default do
            send File.open("foo.txt")
          end
        end
      end
    end

    before do
      File.open("foo.txt", "a") { |f| f.write("foo") }
    end

    after do
      FileUtils.rm("foo.txt")
    end

    it "sends the file" do
      expect(call[2].body).to be_instance_of(File)
    end

    it "automatically sets the type" do
      expect(call[1]["Content-Type"]).to eq("text/plain")
    end

    it "sends inline" do
      expect(call[1]["Content-Disposition"]).to eq("inline")
    end

    context "with a type" do
      def define
        Pakyow::App.define do
          router do
            default do
              send File.open("foo.txt"), type: "application/force-download"
            end
          end
        end
      end

      it "sends with the passed type" do
        expect(call[1]["Content-Type"]).to eq("application/force-download")
      end

      it "sends inline" do
        expect(call[1]["Content-Disposition"]).to eq("inline")
      end
    end

    context "with a name" do
      def define
        Pakyow::App.define do
          router do
            default do
              send File.open("foo.txt"), name: "bar.txt"
            end
          end
        end
      end

      it "sends as an attachment, with the file's name" do
        expect(call[1]["Content-Disposition"]).to eq("attachment; filename=bar.txt")
      end

      it "still sets the type" do
        expect(call[1]["Content-Type"]).to eq("text/plain")
      end
    end

    context "with a type and a name" do
      def define
        Pakyow::App.define do
          router do
            default do
              send File.open("foo.txt"), type: "application/force-download", name: "bar.txt"
            end
          end
        end
      end

      it "sends with the passed type" do
        expect(call[1]["Content-Type"]).to eq("application/force-download")
      end

      it "sends as an attachment, with the passed name" do
        expect(call[1]["Content-Disposition"]).to eq("attachment; filename=bar.txt")
      end
    end
  end

  context "when sending an io object" do
    def define
      Pakyow::App.define do
        router do
          default do
            send StringIO.new("foo")
          end
        end
      end
    end

    it "sends the data" do
      expect(call[2].body.read).to eq("foo")
    end

    it "sends with a default type" do
      expect(call[1]["Content-Type"]).to eq("application/octet-stream")
    end

    it "sends inline" do
      expect(call[1]["Content-Disposition"]).to eq("inline")
    end
  end

  context "when sending a string" do
    def define
      Pakyow::App.define do
        router do
          default do
            send "foo"
          end
        end
      end
    end

    it "sends the string" do
      expect(call[2].body.read).to eq("foo")
    end

    it "sends with a default type" do
      expect(call[1]["Content-Type"]).to eq("application/octet-stream")
    end

    it "sends inline" do
      expect(call[1]["Content-Disposition"]).to eq("inline")
    end
  end
end
