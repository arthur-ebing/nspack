# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module PersonnelIdentifier
      class DeLinkWorker
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:personnel_identifier, :de_link, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/masterfiles/human_resources/personnel_identifiers/#{id}/de_link_contract_worker"
              form.remote!
              form.method :update
              form.add_field :identifier
              form.add_field :contract_worker_id
            end
          end

          layout
        end
      end
    end
  end
end
