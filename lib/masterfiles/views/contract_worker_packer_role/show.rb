# frozen_string_literal: true

module Masterfiles
  module Hr
    module ContractWorkerPackerRole
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:contract_worker_packer_role, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Contract Worker Packer Role'
              form.view_only!
              form.add_field :packer_role
              form.add_field :default_role
              form.add_field :part_of_group_incentive_target
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
