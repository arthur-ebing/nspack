# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/edi/entities/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/interactors/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/jobs/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/repositories/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/schemas/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/services/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/task_permission_checks/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/ui_rules/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/validations/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/edi/views/**/*.rb"].sort.each { |f| require f }

module EdiApp
end
