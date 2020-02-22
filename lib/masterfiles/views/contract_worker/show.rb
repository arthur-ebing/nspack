# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ContractWorker
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:contract_worker, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Contract Worker'
              form.view_only!
              form.add_field :employment_type_id
              form.add_field :contract_type_id
              form.add_field :wage_level_id
              form.add_field :title
              form.add_field :first_name
              form.add_field :surname
              form.add_field :email
              form.add_field :contact_number
              form.add_field :personnel_number
              form.add_field :start_date
              form.add_field :end_date
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
