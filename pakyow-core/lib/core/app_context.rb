module Pakyow
	class AppContext
		attr_reader :request, :response

		def initialize(request = nil, response = nil)
			@request = request
			@response = response
		end
	end
end
