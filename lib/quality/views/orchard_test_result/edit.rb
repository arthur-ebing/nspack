# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
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
            page.section do |section|
              if ui_rule.form_object.api_name == AppConst::PHYT_CLEAN_STANDARD && !ui_rule.form_object.freeze_result
                section.add_control(control_type: :link,
                                    text: 'PUC PhytClean Call',
                                    url: "/quality/test_results/orchard_test_results/#{id}/phyt_clean_request/#{ui_rule.form_object.puc_id}",
                                    style: :button)
              end
            end

            page.form do |form|
              form.action "/quality/test_results/orchard_test_results/#{id}"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :orchard_test_type_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :cultivar_id
                  col.add_field :api_result
                  col.add_field :api_pass_result
                end
                row.column do |col|
                  col.add_field :passed
                  col.add_field :classification
                  col.add_field :freeze_result
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
# rubocop:enable Metrics/BlockLength
