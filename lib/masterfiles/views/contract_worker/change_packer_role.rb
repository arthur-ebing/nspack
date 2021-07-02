# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ContractWorker
      class ChangePackerRole
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:contract_worker, :packer_role, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors

            page.form do |form|
              form.caption 'Change Packer Role'
              form.action "/masterfiles/human_resources/contract_workers/#{id}/change_packer_role"
              form.remote!
              if AppConst::CR_PROD.group_incentive_has_packer_roles?
                form.method :update
              else
                form.view_only!
              end

              form.row do |row|
                row.column do |col|
                  col.add_field :title
                  col.add_field :first_name
                  col.add_field :surname
                  col.add_field :personnel_number
                  if AppConst::CR_PROD.group_incentive_has_packer_roles?
                    col.add_field :packer_role_id
                  else
                    col.add_notice 'Packer roles are not used in this system'
                  end
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
