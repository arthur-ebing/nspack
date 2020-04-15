# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)

# Pre-load included module:
require "#{root_dir}/finished_goods/services/find_or_create_voyage.rb"

Dir["#{root_dir}/finished_goods/entities/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/interactors/*.rb"].sort.each { |f| require f }
# Dir["#{root_dir}/finished_goods/jobs/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/repositories/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/services/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/task_permission_checks/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/ui_rules/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/validations/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/finished_goods/views/**/*.rb"].sort.each { |f| require f }

module FinishedGoodsApp
end
