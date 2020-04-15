# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)

Dir["#{root_dir}/quality/entities/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/interactors/*.rb"].sort.each { |f| require f }
# Dir["#{root_dir}/quality/jobs/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/repositories/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/services/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/task_permission_checks/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/ui_rules/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/validations/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/quality/views/**/*.rb"].sort.each { |f| require f }

module QualityApp
end
