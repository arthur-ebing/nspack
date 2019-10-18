# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/finished_goods/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/finished_goods/interactors/*.rb"].each { |f| require f }
# Dir["#{root_dir}/finished_goods/jobs/*.rb"].each { |f| require f }
Dir["#{root_dir}/finished_goods/repositories/*.rb"].each { |f| require f }
# Dir["#{root_dir}/finished_goods/services/*.rb"].each { |f| require f }
Dir["#{root_dir}/finished_goods/task_permission_checks/*.rb"].each { |f| require f }
Dir["#{root_dir}/finished_goods/ui_rules/*.rb"].each { |f| require f }
Dir["#{root_dir}/finished_goods/validations/*.rb"].each { |f| require f }
Dir["#{root_dir}/finished_goods/views/**/*.rb"].each { |f| require f }

module FinishedGoodsApp
end
