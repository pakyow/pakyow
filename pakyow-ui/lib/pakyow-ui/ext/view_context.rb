class Pakyow::Presenter::ViewContext
  def mutate(mutator, data: nil, with: nil)
    Pakyow::UI::Mutator.instance.mutate(mutator, self, data || with || [])
  end

  def subscribe(qualifications = {})
    raise ArgumentError, 'Cannot subscribe a non-componentized view' unless component?

    channel = Pakyow::UI::ChannelBuilder.build(
      component: component_name,
      qualifications: qualifications,
    )

    context.socket.subscribe(channel)
    attrs.send(:'data-channel=', channel)
    self
  end
end
