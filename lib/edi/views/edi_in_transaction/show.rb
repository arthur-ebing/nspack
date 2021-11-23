# frozen_string_literal: true

module Edi
  module Receipts
    module EdiInTransaction
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:edi_in_transaction, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :flow_type
                  col.add_field :complete
                  col.add_field :schema_valid
                  col.add_field :has_missing_master_files
                  col.add_field :newer_edi_received
                end
                row.column do |col|
                  col.add_field :file_name
                  col.add_field :reprocessed
                  col.add_field :valid
                  col.add_field :has_discrepancies
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :error_message
                  col.add_field :notes
                  col.add_field :backtrace
                  col.add_field :match_data
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :depot_id
                  col.add_field :edi_in_inspection_point
                  col.add_field :edi_in_load_number
                end
              end
            end
          end
        end
      end
    end
  end
end
