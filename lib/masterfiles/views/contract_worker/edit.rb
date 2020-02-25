# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ContractWorker
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:contract_worker, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors

            page.form do |form|
              form.caption 'Edit Contract Worker'
              form.action "/masterfiles/human_resources/contract_workers/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :title
                  col.add_field :first_name
                  col.add_field :surname
                  col.add_field :email
                  col.add_field :contact_number
                  col.add_field :personnel_number
                end
                row.column do |col|
                  col.add_field :employment_type_id
                  col.add_field :contract_type_id
                  col.add_field :wage_level_id
                  col.add_field :shift_type_id
                  col.add_field :start_date
                  col.add_field :end_date
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
