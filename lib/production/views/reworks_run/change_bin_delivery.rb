# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ChangeBinDelivery
        def self.call(reworks_run_type_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:change_bin_delivery, :new, form_values: form_values, reworks_run_type_id: reworks_run_type_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Change Bin Delivery'
              form.action  '/production/reworks/change_bin_delivery'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :from_delivery_id
                  col.add_field :to_delivery_id
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
