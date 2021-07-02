# frozen_string_literal: true

module Masterfiles
  module Quality
    module InspectionType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:inspection_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Inspection Type'
              form.action '/masterfiles/quality/inspection_types'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :inspection_type_code
                  col.add_field :description
                  col.add_field :inspection_failure_type_id
                  col.add_field :passed_default
                end
                row.column do |col|
                  col.add_field :applies_to_all_tms
                  col.add_field :applicable_tm_ids

                  col.add_field :applies_to_all_tm_customers
                  col.add_field :applicable_tm_customer_ids

                  col.add_field :applies_to_all_grades
                  col.add_field :applicable_grade_ids

                  col.add_field :applies_to_all_marketing_org_party_roles
                  col.add_field :applicable_marketing_org_party_role_ids
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
