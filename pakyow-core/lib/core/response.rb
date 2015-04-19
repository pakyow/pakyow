module Pakyow

  # The Response object.
  class Response < Rack::Response
    attr_reader :format

    STATUS_CODE_NAMES = {
      100 => 'Continue',
      101 => 'Switching Protocols',

      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      203 => 'Non-Authoritative Information',
      204 => 'No Content',
      205 => 'Reset Content',
      206 => 'Partial Content',

      300 => 'Multiple Choices',
      301 => 'Moved Permanently',
      302 => 'Found',
      303 => 'See Other',
      304 => 'Not Modified',
      305 => 'Use Proxy',
      306 => 'Switch Proxy',
      307 => 'Temporary Redirect',

      400 => 'Bad Request',
      401 => 'Unauthorized',
      402 => 'Payment Required',
      403 => 'Forbidden',
      404 => 'Not Found',
      405 => 'Method Not Allowed',
      406 => 'Not Acceptable',
      407 => 'Proxy Authentication Required',
      408 => 'Request Timeout',
      409 => 'Conflict',
      410 => 'Gone',
      411 => 'Length Required',
      412 => 'Precondition Failed',
      413 => 'Request Entity Too Large',
      414 => 'Request-URI Too Long',
      415 => 'Unsupported Media Type',
      416 => 'Requested Range Not Satisfiable',
      417 => 'Expectation Failed',
      418 => 'I\'m a teapot',

      500 => 'Internal Server Error',
      501 => 'Not Implemented',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      505 => 'HTTP Version Not Supported',
      506 => 'Variant Also Negotiates',
      507 => 'Insufficient Storage',
      508 => 'Loop Detected',
      509 => 'Bandwidth Limit Exceeded',
      510 => 'Not Extended',
      511 => 'Network Authentication Required'
    }

    STATUS_CODE_LOOKUP = {
      continue: 100,
      switching_protocols: 101,

      ok: 200,
      created: 201,
      accepted: 202,
      non_authoritative_information: 203,
      no_content: 204,
      reset_content: 205,
      partial_content: 206,

      multiple_choices: 300,
      moved_permanently: 301,
      found: 302,
      see_other: 303,
      not_modified: 304,
      use_proxy: 305,
      reserved: 306,
      temporary_redirect: 307,

      bad_request: 400,
      unauthorized: 401,
      payment_required: 402,
      forbidden: 403,
      not_found: 404,
      method_not_allowed: 405,
      not_acceptable: 406,
      proxy_authentication_required: 407,
      request_timeout: 408,
      conflict: 409,
      gone: 410,
      length_required: 411,
      precondition_failed: 412,
      request_entity_too_large: 413,
      request_uri_too_long: 414,
      unsupported_media_type: 415,
      requested_range_not_satisfiable: 416,
      expectation_failed: 417,
      teapot: 418,

      internal_server_error: 500,
      not_implemented: 501,
      bad_gateway: 502,
      service_unavailable: 503,
      gateway_timeout: 504,
      http_version_not_supported: 505,
      variant_also_negotiates: 506,
      insufficient_storage: 507,
      loop_detected: 508,
      bandwidth_exceeded: 509,
      not_extended: 510,
      network_authentication_required: 511
    }

    def initialize(*args)
      super

      self["Content-Type"] ||= 'text/html'
      @format = Rack::Mime::MIME_TYPES.key(type)
    end

    def format=(format)
      @format = format
      self["Content-Type"] = Rack::Mime.mime_type(".#{format}")
    end

    def type
      self["Content-Type"]
    end
  end
end
