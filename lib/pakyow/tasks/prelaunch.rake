# frozen_string_literal: true

desc "Run the prelaunch tasks"
task :prelaunch do |_, args|
  def find_task(task_name)
    Pakyow.tasks.find { |task|
      task.name == task_name.to_s
    } || raise("#{Pakyow::Support::CLI.style.blue(task_name)} is not a prelaunch task")
  end

  def run_task(task_name, task_options)
    task_options[:env] = Pakyow.env
    task = find_task(task_name)

    Pakyow.logger.info "[prelaunch] running: #{task_name}, #{task_options}"
    task.call(task_options)
  end

  Pakyow.boot

  # Run prelaunch tasks registered with the environment.
  #
  Pakyow.config.tasks.prelaunch.each do |task_name, task_options|
    run_task(task_name, task_options)
  end

  # Run prelaunch tasks registered with each pakyow app.
  #
  Pakyow.apps.each do |app|
    if app.is_a?(Pakyow::App)
      app.config.tasks.prelaunch.each do |task_name, task_options|
        task_options[:app] = app
        run_task(task_name, task_options)
      end
    end
  end
end
