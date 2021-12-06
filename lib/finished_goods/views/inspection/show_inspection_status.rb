# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module Inspection
      class ShowInspectionStatus
        def self.call(pallet_inspection_status = nil, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:inspection, :show_status, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Pallet Inspection Status'
              form.action '/finished_goods/inspection/inspections/pallet_inspection_status'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :pallet_number
                  col.add_table pallet_inspection_status,
                                %i[pending_inspections failed_inspections],
                                dom_id: 'inspection_pallet_inspection_status',
                                pivot: true
                end
                row.blank_column
              end
            end
          end

          layout
        end
      end
    end
  end
end
