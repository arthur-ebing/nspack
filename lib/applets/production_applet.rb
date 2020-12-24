# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/production/entities/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/interactors/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/jobs/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/repositories/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/services/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/task_permission_checks/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/ui_rules/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/validations/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/production/views/**/*.rb"].sort.each { |f| require f }

module ProductionApp
end
