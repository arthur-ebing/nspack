# frozen_string_literal: true

module RawMaterials
  module Presorting
    module PresortStagingRun
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:presort_staging_run, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.form do |form|
                form.caption 'Edit Presort Staging Run'
                form.action "/raw_materials/presorting/presort_staging_runs/#{id}"
                # form.remote!
                form.method :update
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

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Staging Run Child',
                                  url: "/raw_materials/presorting/presort_staging_runs/#{id}/staging_run_child",
                                  style: :button,
                                  grid_id: 'presort_staging_run_children',
                                  behaviour: :popup)
              section.add_grid('presort_staging_run_children',
                               "/list/presort_staging_run_children/grid?key=standard&staging_run_id=#{id}",
                               caption: 'Run Children')
            end
          end
        end
      end
    end
  end
end
