# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingPool
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_pool, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Presort Grower Grading Pool'
              form.action "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}"
              form.remote!
              form.method :update
              form.add_field :maf_lot_number
              form.add_field :description
              form.add_field :season_id
              form.add_field :commodity_id
              form.add_field :farm_id
              form.add_field :rmt_bin_count
              form.add_field :rmt_bin_weight
              form.add_field :rmt_codes
            end
          end
        end
      end
    end
  end
end
