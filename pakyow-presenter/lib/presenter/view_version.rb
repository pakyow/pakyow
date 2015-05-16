class Pakyow::Presenter::ViewVersion
  attr_reader :default, :empty, :versions

  def initialize(views)
    @empty    = views.find { |view| view.version == :empty }
    @default  = views.find { |view| !view.doc.get_attribute(:'data-default').nil? } || views.find { |view| view.version != :empty }
    @versions = views
  end

  def initialize_copy(original_view)
    super

    @empty = original_view.empty.soft_copy if original_view.empty
    @versions = original_view.versions.map { |view| view.soft_copy }
    @default = versions.first
  end

  def apply(data, bindings: {}, context: nil, &block)
    data = Array.ensure(data)

    if data.empty?
      @default = @empty
      cleanup
      self
    else
      cleanup

      match(data).bind(data, bindings: bindings, context: context, &block)
    end
  end

  def version(data, &block)
    data = Array.ensure(data)
    coll = ViewCollection.new

    if data.empty?
      @versions.each(&:remove)
    else
      @empty.remove if @empty
      self_dup = self.dup

      view = process_version(self, data.first, &block)
      working = view
      coll << view

      data[1..-1].inject(coll) { |coll, datum|
        duped = self_dup.dup
        view = process_version(duped, datum, &block)

        working.after(view)
        working = view
        coll << view
      }

      coll
    end
  end

  def bind(data, bindings: {}, context: nil, &block)
    @versions.each do |view|
      view.bind(data, bindings: bindings, context: context, &block)
    end
  end

  def use(version)
    @versions.each do |view|
      @default = view if view.version == version
    end

    cleanup

    @default
  end

  def cleanup
    @versions.reject { |view| view == @default }.each(&:remove)
    @versions = [@default]
  end

  def method_missing(method, *args, &block)
    @default.send(method, *args, &block)
  end

  private

  def process_version(version, datum, &block)
    if block.arity == 1
      version.instance_exec(datum, &block)
    else
      block.call(version, datum)
    end

    version.default
  end
end
