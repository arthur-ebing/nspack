# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class New
        def self.call(mode: :new, form_values: nil, form_errors: nil, remote: false) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, mode, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Inspection Sheet'
              form.action '/finished_goods/inspection/govt_inspection_sheets'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :inspector_id
                  col.add_field :inspection_billing_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :booking_reference
                end
                row.column do |col|
                  col.add_field :inspection_point
                  col.add_field :destination_country_id
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
