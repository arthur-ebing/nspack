# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingPool
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_pool, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Presort Grower Grading Pool'
              form.action '/raw_materials/presort_grower_grading/presort_grower_grading_pools'
              form.remote! if remote
              form.add_field :maf_lot_number
            end
          end
        end
      end
    end
  end
end
