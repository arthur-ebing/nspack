# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Govt Inspection Sheet'
              form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :inspector_id
                  col.add_field :inspection_billing_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :booking_reference
                  col.add_field :created_by
                end
                row.column do |col|
                  col.add_field :inspection_point
                  col.add_field :destination_country_id
                  col.add_field :completed
                  col.add_field :inspected
                  col.add_field :reinspection
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
