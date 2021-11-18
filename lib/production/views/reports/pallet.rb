# frozen_string_literal: true

module Production
  module Reports
    module PalletHistory
      class Pallet
        def self.call
          ui_rule = UiRules::Compiler.new(:pallet_history, :pallet)
          rules   = ui_rule.compile
          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Pallet History'
              form.action '/production/reports/pallet_history'
              form.row do |row|
                row.column do |col|
                  col.add_field :pallet_number
                end
                row.blank_column
              end
            end
          end
        end
      end
    end
  end
end
