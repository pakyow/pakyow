RSpec.describe Pakyow::Connection::Statuses do
  KNOWN_CODES = [
    100, 101, 102, 103,
    200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
    300, 301, 302, 303, 304, 305, 306, 307, 308,
    400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 421, 422, 423, 424, 426, 428, 429, 431, 451,
    500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511
  ]

  KNOWN_DESCRIPTIONS = [
    "Continue",
    "Switching Protocols",
    "Processing",
    "Early Hints",
    "OK",
    "Created",
    "Accepted",
    "Non-Authoritative Information",
    "No Content",
    "Reset Content",
    "Partial Content",
    "Multi-Status",
    "Already Reported",
    "IM Used",
    "Multiple Choices",
    "Moved Permanently",
    "Found",
    "See Other",
    "Not Modified",
    "Use Proxy",
    "Switch Proxy",
    "Temporary Redirect",
    "Permanent Redirect",
    "Bad Request",
    "Unauthorized",
    "Payment Required",
    "Forbidden",
    "Not Found",
    "Method Not Allowed",
    "Not Acceptable",
    "Proxy Authentication Required",
    "Request Timeout",
    "Conflict",
    "Gone",
    "Length Required",
    "Precondition Failed",
    "Payload Too Large",
    "URI Too Long",
    "Unsupported Media Type",
    "Range Not Satisfiable",
    "Expectation Failed",
    "Misdirected Request",
    "Unprocessable Entity",
    "Locked",
    "Failed Dependency",
    "Upgrade Required",
    "Precondition Required",
    "Too Many Requests",
    "Request Header Fields Too Large",
    "Unavailable for Legal Reasons",
    "Internal Server Error",
    "Not Implemented",
    "Bad Gateway",
    "Service Unavailable",
    "Gateway Timeout",
    "HTTP Version Not Supported",
    "Variant Also Negotiates",
    "Insufficient Storage",
    "Loop Detected",
    "Not Extended",
    "Network Authentication Required"]

  KNOWN_SYMBOLS = [
    :continue,
    :switching_protocols,
    :processing,
    :early_hints,
    :ok,
    :created,
    :accepted,
    :non_authoritative_information,
    :no_content,
    :reset_content,
    :partial_content,
    :multi_status,
    :already_reported,
    :im_used,
    :multiple_choices,
    :moved_permanently,
    :found,
    :see_other,
    :not_modified,
    :use_proxy,
    :switch_proxy,
    :temporary_redirect,
    :permanent_redirect,
    :bad_request,
    :unauthorized,
    :payment_required,
    :forbidden,
    :not_found,
    :method_not_allowed,
    :not_acceptable,
    :proxy_authentication_required,
    :request_timeout,
    :conflict,
    :gone,
    :length_required,
    :precondition_failed,
    :payload_too_large,
    :uri_too_long,
    :unsupported_media_type,
    :range_not_satisfiable,
    :expectation_failed,
    :misdirected_request,
    :unprocessable_entity,
    :locked,
    :failed_dependency,
    :upgrade_required,
    :precondition_required,
    :too_many_requests,
    :request_header_fields_too_large,
    :unavailable_for_legal_reasons,
    :internal_server_error,
    :not_implemented,
    :bad_gateway,
    :service_unavailable,
    :gateway_timeout,
    :http_version_not_supported,
    :variant_also_negotiates,
    :insufficient_storage,
    :loop_detected,
    :not_extended,
    :network_authentication_required
  ]

  it "contains the expected codes" do
    expect(Pakyow::Connection::Statuses::CODE_TO_DESCRIPTION.keys).to eq(KNOWN_CODES)
  end

  it "contains the expected descriptions" do
    expect(Pakyow::Connection::Statuses::CODE_TO_DESCRIPTION.values).to eq(KNOWN_DESCRIPTIONS)
  end

  it "contains the expected symbols" do
    expect(Pakyow::Connection::Statuses::SYMBOL_TO_CODE.keys).to eq(KNOWN_SYMBOLS)
  end

  describe "::describe" do
    KNOWN_CODES.each_with_index do |code, i|
      it "describes #{code}" do
        expect(Pakyow::Connection::Statuses.describe(code)).to eq(KNOWN_DESCRIPTIONS[i])
      end
    end

    KNOWN_SYMBOLS.each_with_index do |symbol, i|
      it "describes #{symbol}" do
        expect(Pakyow::Connection::Statuses.describe(symbol)).to eq(KNOWN_DESCRIPTIONS[i])
      end
    end

    context "argument is an unknown symbol" do
      it "returns ?" do
        expect(Pakyow::Connection::Statuses.describe(:foo)).to eq("?")
      end
    end

    context "argument is an unknown status code" do
      it "returns ?" do
        expect(Pakyow::Connection::Statuses.describe(-1)).to eq("?")
      end
    end
  end

  describe "::code" do
    KNOWN_CODES.each_with_index do |code, i|
      it "returns the code for #{code}" do
        expect(Pakyow::Connection::Statuses.code(code)).to eq(KNOWN_CODES[i])
      end
    end

    KNOWN_SYMBOLS.each_with_index do |symbol, i|
      it "returns the code for #{symbol}" do
        expect(Pakyow::Connection::Statuses.code(symbol)).to eq(KNOWN_CODES[i])
      end
    end

    context "argument is an unknown symbol" do
      it "returns nil" do
        expect(Pakyow::Connection::Statuses.code(:foo)).to be(nil)
      end
    end

    context "argument is an unknown status code" do
      it "returns nil" do
        expect(Pakyow::Connection::Statuses.code(-1)).to be(nil)
      end
    end
  end
end
