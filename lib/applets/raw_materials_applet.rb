# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/raw_materials/entities/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/interactors/*.rb"].sort.each { |f| require f }
# Dir["#{root_dir}/raw_materials/jobs/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/repositories/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/services/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/task_permission_checks/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/ui_rules/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/validations/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/raw_materials/views/**/*.rb"].sort.each { |f| require f }

module RawMaterialsApp
end
