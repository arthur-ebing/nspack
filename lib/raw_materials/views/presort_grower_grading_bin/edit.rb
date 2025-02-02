# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingBin
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_bin, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Presort Grower Grading Bin'
              form.action "/raw_materials/presort_grower_grading/presort_grower_grading_bins/#{id}"
              form.remote!
              form.method :update
              form.add_field :presort_grower_grading_pool_id
              form.add_field :farm_id
              form.add_field :rmt_class_id
              form.add_field :rmt_size_id
              form.add_field :maf_colour
              form.add_field :maf_class
              form.add_field :maf_count
              form.add_field :maf_weight
            end
          end
        end
      end
    end
  end
end
