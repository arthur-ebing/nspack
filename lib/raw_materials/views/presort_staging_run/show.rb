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
            page.form do |form|
              # form.caption 'Presort Staging Run'
              form.view_only!
              form.add_field :uncompleted_at
              form.add_field :completed
              form.add_field :presort_unit_plant_resource_id
              form.add_field :supplier_id
              form.add_field :completed_at
              form.add_field :canceled
              form.add_field :canceled_at
              form.add_field :cultivar_id
              form.add_field :rmt_class_id
              form.add_field :rmt_size_id
              form.add_field :season_id
              form.add_field :editing
              form.add_field :staged
              form.add_field :active
              form.add_field :legacy_data
            end
          end
        end
      end
    end
  end
end
