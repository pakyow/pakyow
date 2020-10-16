RSpec.shared_context "mirror" do
  def scope(name)
    mirror.scopes.find { |scope|
      scope.named?(name)
    }
  end

  def action(scope, name)
    scope(scope).action(name)
  end

  def endpoint(scope, path)
    scope(scope).endpoints.find { |endpoint|
      endpoint.view_path == path
    }
  end

  def controller(*names, state: controllers)
    name = names.shift.to_sym
    result = state.find { |c|
      c.object_name.name == name
    }

    if names.empty?
      result
    else
      controller(*names, state: result.children)
    end
  end

  let :data do
    Pakyow.app(:test).data
  end

  let :mirror do
    Pakyow.app(:test).mirror
  end

  let :scopes do
    mirror.scopes
  end

  let :endpoints do
    mirror.endpoints
  end
end
