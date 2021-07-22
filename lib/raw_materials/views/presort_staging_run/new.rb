# frozen_string_literal: true

module RawMaterials
  module Presorting
    module PresortStagingRun
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:presort_staging_run, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Presort Staging Run'
              form.action '/raw_materials/presorting/presort_staging_runs'
              form.remote! if remote
              form.add_field :presort_unit_plant_resource_id
              form.add_field :supplier_id
              form.add_field :cultivar_id
              form.add_field :rmt_class_id
              form.add_field :rmt_size_id
              form.add_field :season_id
              if rules[:is_kr]
                form.add_field :ripe_point_code
                form.add_field :track_indicator_code
              end
            end
          end
        end
      end
    end
  end
end
