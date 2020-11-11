# frozen_string_literal: true

require 'axlsx'

namespace :app do
  desc 'Export data to a file'
  task :export, [:key] => [:load_app] do |_, args|
    Crossbeams::ExportData.run(args.key)
  end

  desc 'Export all data at end of season'
  task export_end_of_season: [:load_app] do
    %w[
      eos_bin_loads
      eos_bins
      eos_cartons
      eos_deliveries
      eos_empty_bin_locations
      eos_empty_bin_transactions
      eos_inspection_pallets
      eos_loads
      eos_pallet_sequences
      eos_pallets
      eos_prodrunstats
    ].each do |key|
      puts "\nExtracting for #{key}..."
      Crossbeams::ExportData.run(key)
    end
  end
end
