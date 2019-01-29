RSpec.shared_context "mirror" do
  def scope(name, parent: nil)
    mirror.scopes.find { |scope|
      scope.named?(name) && scope.parent == parent
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

  let :mirror do
    Pakyow::Reflection::Mirror.new(Pakyow.apps.first)
  end

  let :scopes do
    mirror.scopes
  end
end
