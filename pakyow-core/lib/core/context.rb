module Pakyow
	class Context
		attr_accessor :request, :response

		def initialize
			@request = nil
			@response = nil
		end
	end
end