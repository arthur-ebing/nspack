# frozen_string_literal: true

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
              form.view_only!
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
