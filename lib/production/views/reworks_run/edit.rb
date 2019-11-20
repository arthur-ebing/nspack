# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Reworks Run'
              form.action "/production/reworks/reworks_runs/#{id}"
              form.remote!
              form.method :update
              form.add_field :user
              form.add_field :reworks_run_type_id
              form.add_field :remarks
              form.add_field :scrap_reason_id
              form.add_field :pallets_selected
              form.add_field :pallets_affected
              form.add_field :changes_made
              form.add_field :pallets_scrapped
              form.add_field :pallets_unscrapped
            end
          end

          layout
        end
      end
    end
  end
end
