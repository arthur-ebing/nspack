# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/messcada/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/messcada/interactors/*.rb"].each { |f| require f }
# # Dir["#{root_dir}/messcada/jobs/*.rb"].each { |f| require f }
# Dir["#{root_dir}/messcada/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/messcada/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/messcada/services/*.rb"].each { |f| require f }
# # Dir["#{root_dir}/messcada/task_permission_checks/*.rb"].each { |f| require f }
# Dir["#{root_dir}/messcada/ui_rules/*.rb"].each { |f| require f }
Dir["#{root_dir}/messcada/validations/*.rb"].each { |f| require f }
# Dir["#{root_dir}/messcada/views/**/*.rb"].each { |f| require f }

module MesscadaApp
end
