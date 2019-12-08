# frozen_string_literal: true

root_dir = File.expand_path('..', __dir__)
Dir["#{root_dir}/edi/entities/*.rb"].each { |f| require f }
Dir["#{root_dir}/edi/jobs/*.rb"].each { |f| require f }
Dir["#{root_dir}/edi/repositories/*.rb"].each { |f| require f }
Dir["#{root_dir}/edi/schemas/*.rb"].each { |f| require f }
Dir["#{root_dir}/edi/services/*.rb"].each { |f| require f }

module EdiApp
end
