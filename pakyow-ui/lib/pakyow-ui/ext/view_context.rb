class Pakyow::Presenter::ViewContext
  def mutate(mutator, data: nil, with: nil)
    Pakyow::UI::Mutator.instance.mutate(mutator, self, data || with || [])
  end
end
