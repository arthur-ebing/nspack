# frozen_string_literal: true

module Production
  module Reports
    module AvailablePallets
      class Show
        def self.call
          repo = MesscadaApp::MesscadaRepo.new
          rows = repo.gln_status
          delims = ->(a) { UtilityFunctions.delimited_number(a, no_decimals: 0) }

          layout = Crossbeams::Layout::Page.build({}) do |page|
            page.add_text 'Available pallet numbers', wrapper: :h1
            page.add_text 'Number of still available pallet labels for each defined GLN'
            page.add_table(rows,
                           %i[gln used_numbers remaining_numbers est_per_year est_season],
                           top_margin: 2,
                           alignment: { used_numbers: :right,
                                        remaining_numbers: :right,
                                        est_per_year: :right,
                                        est_season: :right },
                           header_captions: { gln: 'GLN',
                                              est_per_year: 'Pallets per season',
                                              est_season: 'Seasons covered' },
                           cell_transformers: { used_numbers: delims,
                                                remaining_numbers: delims,
                                                est_per_year: delims,
                                                est_season: :decimal })
          end
          layout
        end
      end
    end
  end
end
