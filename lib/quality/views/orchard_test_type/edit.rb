# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module Quality
  module Config
    module OrchardTestType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:orchard_test_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Orchard Test Type'
              form.action "/quality/config/orchard_test_types/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :test_type_code
                  col.add_field :description
                  col.add_field :result_type
                  col.add_field :applicable_tm_group_ids
                  col.add_field :applicable_commodity_group_ids
                  col.add_field :applicable_cultivar_ids
                  col.add_field :api_name
                  col.add_field :result_attributes
                end
                row.column do |col|
                  col.add_field :applies_to_all_markets
                  col.add_field :applies_to_all_cultivars
                  col.add_field :applies_to_orchard
                  col.add_field :applies_to_orchard_set
                  col.add_field :allow_result_capturing
                  col.add_field :pallet_level_result
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
