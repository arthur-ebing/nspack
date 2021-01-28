# frozen_string_literal: true

module Production
  module Production
    module Shift
      class SearchByContractWorker
        def self.call(form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:shift, :search, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/production/shifts/group_incentives/search_by_contract_worker'
              form.caption 'Search group incentives by contract worker'

              form.row do |row|
                row.column do |col|
                  col.add_field :contract_worker_id
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
