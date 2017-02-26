module Pakyow
  Controller.before :process do
    @cookies = request.cookies.dup
  end

  Controller.after :process do
    request.cookies.each_pair do |name, value|
      name = name.to_s

      # delete the cookie if the value has been set to nil
      response.delete_cookie(name) if value.nil?

      # cookie is already set with value, ignore
      next if @cookies.include?(name) && @cookies[name] == value

      # set cookie with defaults
      response.set_cookie(name, {
        path: config.cookies.path,
        expires: config.cookies.expiration,
        value: value
      })
    end

    # delete cookies that were deleted from the request
    (@cookies.keys - request.cookies.keys).each do |name|
      response.delete_cookie(name)
    end
  end
end
