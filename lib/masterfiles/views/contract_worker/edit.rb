# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ContractWorker
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:contract_worker, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Contract Worker'
              form.action "/masterfiles/human_resources/contract_workers/#{id}"
              form.remote!
              form.method :update
              form.add_field :employment_type_id
              form.add_field :contract_type_id
              form.add_field :wage_level_id
              form.add_field :title
              form.add_field :full_names
              form.add_field :surname
              form.add_field :email
              form.add_field :contact_number
              form.add_field :personnel_number
              form.add_field :start_date
              form.add_field :end_date
            end
          end

          layout
        end
      end
    end
  end
end
