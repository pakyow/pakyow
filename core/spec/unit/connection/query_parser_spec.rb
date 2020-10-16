RSpec.describe Pakyow::Connection::QueryParser do
  let :parser do
    described_class.new
  end

  describe "#parse" do
    it "adds to the params" do
      parser.parse("foo=bar")
      parser.parse("bar=baz")
      expect(parser.params).to eq("foo" => "bar", "bar" => "baz")
    end

    it "strips keys and values" do
      parser.parse(" foo = bar   ")
      expect(parser.params).to eq("foo" => "bar")
    end

    describe "parsed values" do
      PARSING_TESTS = {
        nil => {},
        "foo" => { "foo" => nil },
        "foo=bar" => { "foo" => "bar" },
        "foo=\"bar\"" => { "foo" => "\"bar\"" },
        "foo=bar&foo=baz" => { "foo" => ["bar", "baz"] },
        "foo=1&bar=2" => { "foo" => "1", "bar" => "2" },
        "my+weird+field=q1%212%22%27w%245%267%2Fz8%29%3F" => { "my weird field" => "q1!2\"'w$5&7/z8)?" },
        "foo%3Dbaz=bar" => { "foo=baz" => "bar" },
        "=" => {},
        "=value" => {},
        "key=" => { "key" => "" },
        "&key&" => { "key" => nil },
        ";key;" => { "key" => nil },
        ",key," => { "key" => nil },
        ";foo=bar,;" => { "foo" => "bar" },
        ",foo=bar;," => { "foo" => "bar" },
        "foo&foo=" => { "foo" => "" },
        "&foo=1&&bar=2" => { "foo" => "1", "bar" => "2" },
        "foo&bar=" => { "foo" => nil, "bar" => "" },
        "foo=bar&baz=" => { "foo" => "bar", "baz" => "" },
        "a=b&pid%3D1234=1023" => { "pid=1234" => "1023", "a" => "b" },

        "foo[]" => { "foo" => [nil] },
        "foo[]=" => { "foo" => [""] },
        "foo[]=bar" => { "foo" => ["bar"] },
        "foo[]=bar&foo" => { "foo" => nil },
        "foo[]=bar&foo[]" => { "foo" => ["bar", nil] },
        "foo[]=bar&foo[]=" => { "foo" => ["bar", ""] },
        "foo[]=1&foo[]=2" => { "foo" => ["1", "2"] },
        "foo=bar&baz[]=1&baz[]=2&baz[]=3" => { "foo" => "bar", "baz" => ["1", "2", "3"] },
        "foo[]=bar&baz[]=1&baz[]=2&baz[]=3" => { "foo" => ["bar"], "baz" => ["1", "2", "3"] },

        "x[y]=1" => { "x" => { "y" => "1" } },
        "x[y][z]=1" => { "x" => { "y" => { "z" => "1" } } },
        "x[y][z][]=1" => { "x" => { "y" => { "z" => ["1"] } } },
        "x[y][z]=1&x[y][z]=2" => { "x" => { "y" => { "z" => "2" } } },
        "x[y][z][]=1&x[y][z][]=2" => { "x" => { "y" => { "z" => ["1", "2"] } } },
        "x[y][][z]=1" => { "x" => { "y" => [ { "z" => "1" } ] } },
        "x[y][][z][]=1" => { "x" => { "y" => [ { "z" => ["1"] } ] } },
        "x[y][][z]=1&x[y][][w]=2" => { "x" => { "y" => [ { "z" => "1", "w" => "2" } ] } },
        "x[y][][v][w]=1" => { "x" => { "y" => [ { "v" => { "w" => "1" } } ] } },
        "x[y][][z]=1&x[y][][v][w]=2" => { "x" => { "y" => [ { "z" => "1", "v" => { "w" => "2" } } ] } },
        "x[y][][z]=1&x[y][][z]=2" => { "x" => {"y" => [ { "z" => "1" }, { "z" => "2" } ] } },
        "x[y][][z]=1&x[y][][w]=a&x[y][][z]=2&x[y][][w]=3" => { "x" => { "y" => [ { "z" => "1", "w" => "a" }, { "z" => "2", "w" => "3" } ] } },
        "x[][y]=1&x[][z][w]=a&x[][y]=2&x[][z][w]=b" => { "x" => [ { "y" => "1", "z" => { "w" => "a" } }, { "y" => "2", "z" => { "w" => "b" } } ] },
        "x[][z][w]=a&x[][y]=1&x[][z][w]=b&x[][y]=2" => { "x" => [ { "y" => "1", "z" => { "w" => "a" } }, { "y" => "2", "z" => { "w" => "b" } } ] },
        "data[books][][data][page]=1&data[books][][data][page]=2" => { "data" => { "books" => [ { "data" => { "page" => "1" } }, { "data" => { "page" => "2" } } ] } },

        "foo[]=bar&foo[" => { "foo" => ["bar"], "foo[" => nil },
        "foo[]=bar&foo]" => { "foo" => ["bar"], "foo]" => nil },
        "foo[]=bar&f[oo" => { "foo" => ["bar"], "f[oo" => nil },
        "foo[]=bar&f]oo" => { "foo" => ["bar"], "f]oo" => nil },
        "foo[]=bar&foo[=baz" => { "foo" => ["bar"], "foo[" => "baz" },
        "foo[]=bar&f[oo=baz" => { "foo" => ["bar"], "f[oo" => "baz" },
        "foo[]=bar&foo]=baz" => { "foo" => ["bar"], "foo]" => "baz" },
        "foo[]=bar&f]oo=baz" => { "foo" => ["bar"], "f]oo" => "baz" },
      }.freeze

      PARSING_TESTS.each do |input, output|
        it "parses `#{input}`" do
          parser.parse(input)
          expect(parser.params).to eq(output)
        end
      end
    end

    describe "parsing failures" do
      PARSING_FAILURES = {
        "x[y]=1&x[y]z=2" => [Pakyow::Connection::QueryParser::InvalidParameter, "expected `y' to be Hash (got String)"],
        "x[y]=1&x[]=1" => [Pakyow::Connection::QueryParser::InvalidParameter, "expected `x' to be Array (got Hash)"],
        "x[y]=1&x[y][][w]=2" => [Pakyow::Connection::QueryParser::InvalidParameter, "expected `y' to be Array (got String)"],
      }.freeze

      PARSING_FAILURES.each do |input, (error_class, error_message)|
        it "fails to parse `#{input}`" do
          expect {
            parser.parse(input)
          }.to raise_error do |error|
            expect(error).to be_instance_of(error_class)
            expect(error.message).to eq(error_message)
          end
        end
      end
    end

    describe "key space failures" do
      let :parser do
        described_class.new(key_space_limit: 5)
      end

      it "raises an error when the configured key space size is exceeded" do
        expect {
          parser.parse("foo=baz")
        }.not_to raise_error

        expect {
          parser.parse("foobar=baz")
        }.to raise_error do |error|
          expect(error).to be_instance_of(Pakyow::Connection::QueryParser::KeySpaceLimitExceeded)
          expect(error.message).to eq("key space limit (5) exceeded by `foobar'")
        end
      end
    end

    describe "depth failures" do
      let :parser do
        described_class.new(depth_limit: 1)
      end

      it "raises an error when the configured depth is exceeded" do
        expect {
          parser.parse("foo=baz")
        }.not_to raise_error

        expect {
          parser.parse("bar[]=baz")
        }.not_to raise_error

        expect {
          parser.parse("baz[][x]=baz")
        }.to raise_error do |error|
          expect(error).to be_instance_of(Pakyow::Connection::QueryParser::DepthLimitExceeded)
          expect(error.message).to eq("depth limit (1) exceeded by `x'")
        end
      end
    end
  end

  describe "key space limit" do
    it "has a default value" do
      expect(parser.key_space_limit).to eq(102400)
    end
  end

  describe "depth limit" do
    it "has a default value" do
      expect(parser.depth_limit).to eq(100)
    end
  end

  describe "passing a params object" do
    let :parser do
      described_class.new(params: params)
    end

    let :params do
      {}
    end

    before do
      parser.parse("foo=bar")
    end

    it "uses the passed params object" do
      expect(params).to eq("foo" => "bar")
    end
  end

  describe "passing an indifferent hash as a params object" do
    let :parser do
      described_class.new(params: params)
    end

    let :params do
      Pakyow::Support::IndifferentHash.new
    end

    before do
      parser.parse("foo=bar&bar[baz]=qux")
    end

    it "builds params correctly" do
      expect(params).to eq(foo: "bar", bar: { baz: "qux" })
    end
  end
end
