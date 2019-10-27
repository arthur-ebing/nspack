# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/production/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/interactors/*.rb"].each { |f| require f }
# Dir["#{root_dir}/production/jobs/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/services/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/task_permission_checks/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/ui_rules/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/validations/*.rb"].each { |f| require f }
Dir["#{root_dir}/production/views/**/*.rb"].each { |f| require f }

module ProductionApp
end
