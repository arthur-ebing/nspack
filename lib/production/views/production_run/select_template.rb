# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class SelectTemplate
        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :template, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Production Run'
              form.action "/production/runs/production_runs/#{id}/select_template"
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :packhouse_resource_id
                  col.add_field :farm_id
                  col.add_field :orchard_id
                  col.add_field :cultivar_group_id
                  col.add_field :product_setup_template_id
                end
                row.column do |col|
                  col.add_field :production_line_id
                  col.add_field :puc_id
                  col.add_field :season_id
                  col.add_field :cultivar_id
                  col.add_field :allow_cultivar_mixing
                  col.add_field :allow_orchard_mixing
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
