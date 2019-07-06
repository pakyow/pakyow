RSpec.shared_context "options_for" do
  include_context "app"

  let :view_path do
    "/presentation/forms/options_for"
  end

  let :binding do
    :tag
  end

  let :app_init do
    local = self
    Proc.new do
      presenter local.view_path do
        render node: -> { form(:post) } do
          setup do |form|
            instance_exec(form, &local.perform)
          end
        end
      end
    end
  end

  let :perform do
    local = self
    Proc.new do |form|
      if local.respond_to?(:block)
        form.options_for(local.binding, &local.block)
      else
        form.options_for(local.binding, local.options)
      end
    end
  end

  let :rendered do
    call(view_path)[2].tap do |rendered|
      rendered.gsub!(/<input type="hidden" name="pw-form" value="[^>]*">/, "")
    end
  end
end
