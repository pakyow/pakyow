RSpec.describe Pakyow::Connection::MultipartParser do
  let :parser do
    described_class.new(params, boundary: boundary)
  end

  let :boundary do
    "AaB03x"
  end

  let :params do
    Pakyow::Connection::Params.new
  end

  def parse(fixture)
    parser.parse(input(fixture))
  end

  def input(fixture)
    Async::HTTP::Body::Buffered.wrap(data(fixture))
  end

  def data(fixture)
    File.open(File.expand_path("../multipart_parser/fixtures/#{fixture}", __FILE__), "rb")
  end

  context "single param" do
    it "parses the input" do
      expect(parse(:single_form_data)).to eq("foo" => "bar")
    end
  end

  context "nested param" do
    it "parses the input" do
      expect(parse(:nested_form_data)).to eq("foo" => { "bar" => "baz" })
    end
  end

  context "multiple params" do
    it "parses the input" do
      expect(parse(:multiple_form_data)).to eq("foo" => "bar", "bar" => "baz")
    end
  end

  context "single file" do
    let :parsed do
      parse(:single_file)
    end

    it "parses" do
      expect(parsed.keys).to eq(["foo"])
      expect(parsed["foo"]).to be_instance_of(Pakyow::Connection::MultipartInput)
    end

    it "sets the filename" do
      expect(parsed[:foo].filename).to eq("foo.png")
    end

    it "sets the headers" do
      expect(parsed[:foo].headers).to eq({
        "content-disposition" => "form-data; name=\"foo\"; filename=foo.png",
        "content-type" => "image/png"
      })
    end

    it "sets the type" do
      expect(parsed[:foo].type).to eq("image/png")
    end

    it "sets the input content" do
      expect(parsed[:foo].read).to eq("contents")
    end

    it "sets the input name" do
      basename = File.basename(parsed[:foo].path)
      expect(basename).to start_with("PakyowMultipart")
      expect(basename).to end_with(".png")
    end
  end

  context "nested file" do
    let :parsed do
      parse(:nested_file)
    end

    it "parses" do
      expect(parsed.keys).to eq(["foo", "bar"])
      expect(parsed[:foo]).to be_instance_of(Pakyow::Connection::MultipartInput)
      expect(parsed[:bar][:baz]).to be_instance_of(Pakyow::Connection::MultipartInput)
    end

    it "sets each input's filename" do
      expect(parsed[:foo].filename).to eq("foo.png")
      expect(parsed[:bar][:baz].filename).to eq("bar.jpg")
    end

    it "sets each input's headers" do
      expect(parsed[:foo].headers).to eq({
        "content-disposition" => "form-data; name=\"foo\"; filename=foo.png",
        "content-type" => "image/png"
      })

      expect(parsed[:bar][:baz].headers).to eq({
        "content-disposition" => "form-data; name=\"bar[baz]\"; filename=bar.jpg",
        "content-type" => "image/jpg"
      })
    end

    it "sets each input's type" do
      expect(parsed[:foo].type).to eq("image/png")
      expect(parsed[:bar][:baz].type).to eq("image/jpg")
    end

    it "sets each input's content" do
      expect(parsed[:foo].read).to eq("contents1")
      expect(parsed[:bar][:baz].read).to eq("contents2")
    end

    it "sets each input's tempfile name" do
      basename = File.basename(parsed[:foo].path)
      expect(basename).to start_with("PakyowMultipart")
      expect(basename).to end_with(".png")

      basename = File.basename(parsed[:bar][:baz].path)
      expect(basename).to start_with("PakyowMultipart")
      expect(basename).to end_with(".jpg")
    end
  end

  context "params and files" do
    let :parsed do
      parse(:params_and_files)
    end

    it "parses" do
      expect(parsed[:foo]).to eq("bar")
      expect(parsed[:bar]).to be_instance_of(Pakyow::Connection::MultipartInput)
    end
  end

  context "mixed" do
    let :parsed do
      parse(:mixed)
    end

    it "parses" do
      expect(parsed[:foo]).to eq("bar")
      expect(parsed[:files]).to be_instance_of(String)
      expect(parsed[:files].size).to eq(252)
    end
  end

  describe "limiting parts" do
    def data(_)
      StringIO.new(String.new.tap { |data|
        1024.times do |i|
          data << "--#{boundary}\r\n"
          data << "Content-Type: image/png\r\n"
          data << "Content-Disposition: form-data; name=\"foo#{i}\"; filename=foo#{i}.png\r\n\r\n"
          data << "contents#{i}\r\n"
        end

        data << "--#{boundary}--\r\n"
      })
    end

    it "errors when the limit is reached" do
      expect {
        parse(:above_limit)
      }.to raise_error(Pakyow::Connection::MultipartParser::LimitExceeded, "multipart limit (100) exceeded")
    end

    it "does not process more than the limit" do
      begin
        parse(:above_limit)
      rescue
      end

      expect(params.keys.count).to eq(100)
    end

    it "closes each file" do
      begin
        parse(:above_limit)
      rescue
      end

      params.values.each do |value|
        expect(value.closed?).to be(true)
      end
    end
  end

  describe "setting encodings" do
    context "content type is US_ASCII" do
      let :parsed do
        parse(:content_type_us_ascii)
      end

      it "parses as US_ASCII" do
        expect(parsed[:text]).to eq("contents")
        expect(parsed[:text].encoding).to eq(Encoding::US_ASCII)
      end
    end

    context "content type is missing" do
      let :parsed do
        parse(:content_type_default)
      end

      it "parses as UTF_8" do
        expect(parsed[:text]).to eq("contents")
        expect(parsed[:text].encoding).to eq(Encoding::UTF_8)
      end
    end

    context "content type is quoted" do
      let :parsed do
        parse(:content_type_quoted)
      end

      it "parses as UTF_8" do
        expect(parsed[:text]).to eq("contents")
        expect(parsed[:text].encoding).to eq(Encoding::UTF_8)
      end
    end
  end

  describe "handling parsing errors" do
    context "invalid input" do
      it "raises an error" do
        expect {
          parse(:invalid_input)
        }.to raise_error(Pakyow::Connection::MultipartParser::ParseError, "unknown encoding name - FOO")
      end

      it "does not process after the error" do
        begin
          parse(:invalid_input)
        rescue
        end

        expect(params.keys.count).to eq(2)
      end

      it "closes each input processed before the error" do
        begin
          parse(:invalid_input)
        rescue
        end

        params.values.each do |value|
          expect(value.closed?).to be(true) if value.respond_to?(:closed)
        end
      end
    end

    context "missing a boundary" do
      let :boundary do
        ""
      end

      it "raises an error" do
        expect {
          parse(:single_form_data)
        }.to raise_error(Pakyow::Connection::MultipartParser::ParseError, "Parser error, 2 of 10 bytes parsed")
      end
    end
  end

  context "name is not provided" do
    context "filename is provided" do
      let :parsed do
        parse(:no_name_with_filename)
      end

      it "uses the filename" do
        expect(parsed.keys).to eq(["foo.png"])
      end
    end

    context "filename is not provided" do
      let :parsed do
        parse(:no_name)
      end

      it "does not include the input" do
        expect(parsed.keys).to be_empty
      end
    end
  end

  context "boundary is quoted" do
    let :boundary do
      %("AaB:03x")
    end

    let :parsed do
      parse(:quoted_boundary)
    end

    it "parses" do
      expect(parsed.keys.count).to eq(3)
    end
  end

  context "internet explorer upload" do
    let :parsed do
      parse(:internet_explorer)
    end

    it "parses" do
      expect(parsed[:files].filename).to eq("\"C:\\Documents and Settings\\Administrator\\Desktop\\file1.txt\"")
    end
  end
end
