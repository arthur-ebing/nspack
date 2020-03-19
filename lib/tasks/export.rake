# frozen_string_literal: true

namespace :app do
  desc 'Export data to a file'
  task :export, [:key] => [:load_app] do |_, args|
    Crossbeams::ExportData.run(args.key)
  end
end
