# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Quality
  module TestResults
    module OrchardTestResult
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:orchard_test_result, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Orchard Test Result'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :orchard_test_type_id
                  col.add_field :orchard_set_result_id
                  col.add_field :puc_id
                  col.add_field :orchard_id
                  col.add_field :cultivar_ids
                  col.add_field :description
                  col.add_field :status_description
                  col.add_field :api_result
                  col.add_field :classifications
                end
                row.column do |col|
                  col.add_field :passed
                  col.add_field :classification_only
                  col.add_field :freeze_result
                  col.add_field :applicable_from
                  col.add_field :applicable_to
                  col.add_field :active
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
