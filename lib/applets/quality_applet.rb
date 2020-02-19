# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/quality/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/interactors/*.rb"].each { |f| require f }
# Dir["#{root_dir}/quality/jobs/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/services/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/task_permission_checks/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/ui_rules/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/validations/*.rb"].each { |f| require f }
Dir["#{root_dir}/quality/views/**/*.rb"].each { |f| require f }

module QualityApp
end
