# frozen_string_literal: true

module Pakyow
  class Connection
    # @api private
    class Statuses
      CODE_TO_DESCRIPTION = {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",
        103 => "Early Hints",

        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-Authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        208 => "Already Reported",
        226 => "IM Used",

        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        # no longer used, but included for completeness
        306 => "Switch Proxy",
        307 => "Temporary Redirect",
        308 => "Permanent Redirect",

        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Payload Too Large",
        414 => "URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Range Not Satisfiable",
        417 => "Expectation Failed",
        421 => "Misdirected Request",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",
        428 => "Precondition Required",
        429 => "Too Many Requests",
        431 => "Request Header Fields Too Large",
        451 => "Unavailable for Legal Reasons",

        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        506 => "Variant Also Negotiates",
        507 => "Insufficient Storage",
        508 => "Loop Detected",
        510 => "Not Extended",
        511 => "Network Authentication Required"
      }.freeze

      SYMBOL_TO_CODE = Hash[CODE_TO_DESCRIPTION.map { |code, message|
        [message.downcase.gsub(/[^a-z]/, "_").to_sym, code]
      }].freeze

      class << self
        # Returns the string representation for a status code or symbolized status name.
        #
        # @example
        #   Pakyow::Connection::Statuses.describe(200)
        #   => "OK"
        #
        #   Pakyow::Connection::Statuses.describe(:ok)
        #   => "OK"
        #
        def describe(code_or_symbol)
          CODE_TO_DESCRIPTION[code(code_or_symbol)] || "?"
        end

        # Returns the status code for the symbolized status name.
        #
        # @example
        #   Pakyow::Connection::Statuses.code(:ok)
        #   => 200
        #
        #   Pakyow::Connection::Statuses.code(200)
        #   => 200
        #
        def code(code_or_symbol)
          case code_or_symbol
          when Symbol
            SYMBOL_TO_CODE[code_or_symbol]
          else
            code_or_symbol = code_or_symbol.to_i
            if CODE_TO_DESCRIPTION.key?(code_or_symbol)
              code_or_symbol
            else
              nil
            end
          end
        end
      end
    end
  end
end
