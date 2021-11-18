# frozen_string_literal: true

module Edi
  module Viewer
    module File
      class CSV
        def self.call(flow_type, file, upload_name: nil)
          recs = ::CSV.read(file,
                            col_sep: AppConst::CR_EDI.csv_column_separator(flow_type), # flow_type),
                            force_quotes: AppConst::CR_EDI.csv_force_quotes(flow_type), # flow_type),
                            headers: true)
          col_defs = Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
            recs.first.to_a.each { |key, _| mk.col key }
          end
          row_defs = recs.map { |r| Hash[r.to_a] }

          Crossbeams::Layout::Page.build({}) do |page|
            page.form_object OpenStruct.new(search: nil)
            page.add_text flow_type.upcase, wrapper: :h3
            page.section do |section|
              section.fit_height!
              section.add_grid('edi_out_csv',
                               '',
                               col_defs: col_defs,
                               row_defs: row_defs,
                               caption: "#{flow_type} - #{upload_name || file}")
            end
          end
        end
      end
    end
  end
end
