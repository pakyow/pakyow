state :todo do
  def foo
  end

  Proc.new do
  end
end

state :foo do
  FOO = "foo"
end

state :bar do
  FOO = "bar"
end
