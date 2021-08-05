# frozen_string_literal: true

module RawMaterials
  module Presorting
    module PresortStagingRunChild
      class New
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:presort_staging_run_child, :new, form_values: form_values, staging_run_id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Presort Staging Run Child'
              form.action "/raw_materials/presorting/presort_staging_runs/#{id}/staging_run_child"
              form.remote! if remote
              form.add_field :farm_id
            end
          end
        end
      end
    end
  end
end
