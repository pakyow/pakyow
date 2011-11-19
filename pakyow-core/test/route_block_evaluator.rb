# Evaluates a route block and keeps up with method calls made.
#
class RouteBlockEvaluator
  def initialize(block, *args)
    self.instance_exec &block#(args)
  end
  
  def request
    @request ||= Request.new({})
  end
  
  def method_missing(method, *args)
    puts method
  end
end
