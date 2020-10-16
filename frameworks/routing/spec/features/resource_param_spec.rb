RSpec.describe "resource params" do
  include_context "app"

  let :app_def do
    Proc.new {
      resource :posts, "/posts" do
        list do
          send Marshal.dump(params)
        end

        show do
          send Marshal.dump(params)
        end
      end
    }
  end

  it "does not set for list" do
    expect(Marshal.load(call("/posts")[2])).to eq({})
  end

  it "sets :id for show" do
    expect(Marshal.load(call("/posts/1")[2])[:id]).to eq("1")
  end

  it "sets :{singular_name}_id for show" do
    expect(Marshal.load(call("/posts/2")[2])[:post_id]).to eq("2")
  end

  context "custom param" do
    let :app_def do
      Proc.new {
        resource :posts, "/posts", param: :slug do
          list do
            send Marshal.dump(params)
          end

          show do
            send Marshal.dump(params)
          end
        end
      }
    end

    it "does not set for list" do
      expect(Marshal.load(call("/posts")[2])).to eq({})
    end

    it "sets :{param} for show" do
      expect(Marshal.load(call("/posts/one")[2])[:slug]).to eq("one")
    end

    it "sets :{singular_name}_{param} for show" do
      expect(Marshal.load(call("/posts/two")[2])[:post_slug]).to eq("two")
    end
  end
end
