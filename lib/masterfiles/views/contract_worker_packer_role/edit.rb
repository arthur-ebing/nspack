# frozen_string_literal: true

module Masterfiles
  module Hr
    module ContractWorkerPackerRole
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:contract_worker_packer_role, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Contract Worker Packer Role'
              form.action "/masterfiles/human_resources/contract_worker_packer_roles/#{id}"
              form.remote!
              form.method :update
              form.add_field :packer_role
              form.add_field :default_role
              form.add_field :part_of_group_incentive_target
            end
          end

          layout
        end
      end
    end
  end
end
