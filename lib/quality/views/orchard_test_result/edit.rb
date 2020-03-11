# frozen_string_literal: true

module Quality
  module TestResults
    module OrchardTestResult
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:orchard_test_result, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Orchard Test Result'
              form.action "/quality/test_results/orchard_test_results/#{id}"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :orchard_test_type_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :cultivar_id
                  col.add_field :description
                  col.add_field :classification
                end
                row.column do |col|
                  col.add_field :passed
                  col.add_field :classification_only
                  col.add_field :freeze_result
                  col.add_field :applicable_from
                  col.add_field :applicable_to
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
