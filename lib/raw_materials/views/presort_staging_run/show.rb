# frozen_string_literal: true

module RawMaterials
  module Presorting
    module PresortStagingRun
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:presort_staging_run, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.form do |form|
                form.caption 'Presort Staging Run'
                form.view_only!
                form.row do |row|
                  row.column do |col|
                    col.add_field :presort_unit_plant_resource_id
                    col.add_field :supplier_id
                    col.add_field :cultivar_id
                    col.add_field :rmt_class_id
                    col.add_field :rmt_size_id
                    col.add_field :ripe_point_code if rules[:is_kr]
                  end
                  row.column do |col|
                    col.add_field :track_indicator_code if rules[:is_kr]
                    col.add_field :season_id
                    col.add_field :editing
                    col.add_field :staged
                    col.add_field :active
                    col.add_field :canceled
                  end
                  row.column do |col|
                    col.add_field :canceled_at
                    col.add_field :setup_uncompleted_at
                    col.add_field :setup_completed
                    col.add_field :setup_completed_at
                  end
                end
              end
            end

            page.section do |section|
              section.add_grid('presort_staging_run_children',
                               "/list/presort_staging_run_children_view/grid?key=standard&staging_run_id=#{id}",
                               caption: 'Run Children')
            end
          end
        end
      end
    end
  end
end
