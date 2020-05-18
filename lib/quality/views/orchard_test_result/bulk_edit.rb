# frozen_string_literal: true

module Quality
  module TestResults
    module OrchardTestResult
      class BulkEdit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:orchard_test_result, :bulk_edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/quality/test_results/orchard_test_results/#{id}/bulk_edit"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :orchard_test_type_id
                  col.add_field :api_result
                  col.add_field :api_pass_result
                end
                row.column do |col|
                  col.add_field :passed
                  col.add_field :classification
                  col.add_field :freeze_result
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :update_all
                  col.add_field :group_ids
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
