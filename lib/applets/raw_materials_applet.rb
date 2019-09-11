# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/raw_materials/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/interactors/*.rb"].each { |f| require f }
# Dir["#{root_dir}/raw_materials/jobs/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/services/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/task_permission_checks/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/ui_rules/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/validations/*.rb"].each { |f| require f }
Dir["#{root_dir}/raw_materials/views/**/*.rb"].each { |f| require f }

module RawMaterialsApp
end
