# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)

# Pre-load included module:
require "#{root_dir}/label_printing/services/label_content.rb"

Dir["#{root_dir}/messcada/entities/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/interactors/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/jobs/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/repositories/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/services/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/task_permission_checks/*.rb"].sort.each { |f| require f }
# Dir["#{root_dir}/messcada/ui_rules/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/validations/*.rb"].sort.each { |f| require f }
Dir["#{root_dir}/messcada/views/**/*.rb"].sort.each { |f| require f }

module MesscadaApp
end
