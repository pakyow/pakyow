RSpec.describe "sending data" do
  include_context "app"

  context "when sending a file" do
    let :app_def do
      Proc.new {
        controller do
          default do
            send File.open("foo.txt")
          end
        end
      }
    end

    before do
      File.open("foo.txt", "a") { |f| f.write("foo") }
    end

    after do
      FileUtils.rm("foo.txt")
    end

    it "sends the file" do
      expect(call[2]).to eq("foo")
    end

    it "automatically sets the type" do
      expect(call[1]["content-type"]).to eq("text/plain")
    end

    it "sends inline" do
      expect(call[1]["content-disposition"]).to eq("inline")
    end

    context "with a type" do
      let :app_def do
        Proc.new {
          controller do
            default do
              send File.open("foo.txt"), type: "application/force-download"
            end
          end
        }
      end

      it "sends with the passed type" do
        expect(call[1]["content-type"]).to eq("application/force-download")
      end

      it "sends inline" do
        expect(call[1]["content-disposition"]).to eq("inline")
      end
    end

    context "with a name" do
      let :app_def do
        Proc.new {
          controller do
            default do
              send File.open("foo.txt"), name: "bar.txt"
            end
          end
        }
      end

      it "sends as an attachment, with the file's name" do
        expect(call[1]["content-disposition"]).to eq("attachment; filename=bar.txt")
      end

      it "still sets the type" do
        expect(call[1]["content-type"]).to eq("text/plain")
      end
    end

    context "with a type and a name" do
      let :app_def do
        Proc.new {
          controller do
            default do
              send File.open("foo.txt"), type: "application/force-download", name: "bar.txt"
            end
          end
        }
      end

      it "sends with the passed type" do
        expect(call[1]["content-type"]).to eq("application/force-download")
      end

      it "sends as an attachment, with the passed name" do
        expect(call[1]["content-disposition"]).to eq("attachment; filename=bar.txt")
      end
    end
  end

  context "when sending an io object" do
    let :app_def do
      Proc.new {
        controller do
          default do
            send StringIO.new("foo")
          end
        end
      }
    end

    it "sends the data" do
      expect(call[2]).to eq("foo")
    end

    it "sends with a default type" do
      expect(call[1]["content-type"]).to eq("application/octet-stream")
    end

    it "sends inline" do
      expect(call[1]["content-disposition"]).to eq("inline")
    end
  end

  context "when sending a string" do
    let :app_def do
      Proc.new {
        controller do
          default do
            send "foo"
          end
        end
      }
    end

    it "sends the string" do
      expect(call[2]).to eq("foo")
    end

    it "does not set a content type" do
      expect(call[1]["content-type"]).to eq(nil)
    end

    it "sends inline" do
      expect(call[1]["content-disposition"]).to eq("inline")
    end

    context "and a type is specified" do
      let :app_def do
        Proc.new {
          controller do
            default do
              send "foo", type: "application/json"
            end
          end
        }
      end

      it "sends with the specified type" do
        expect(call[1]["content-type"]).to eq("application/json")
      end
    end
  end

  context "when sending an unsupported type" do
    let :app_def do
      Proc.new {
        controller do
          handle ArgumentError, as: 500 do
            $error = connection.error
          end

          default do
            send TrueClass
          end
        end
      }
    end

    let :allow_request_failures do
      true
    end

    before do
      call
    end

    it "raises an ArgumentError" do
      expect($error).to be_instance_of(ArgumentError)
    end
  end
end
