# frozen_string_literal: true

module Quality
  module Config
    module OrchardTestType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:orchard_test_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Test Type'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :test_type_code
                  col.add_field :description
                  col.add_field :result_type
                  col.add_field :api_name
                  col.add_field :api_attribute
                  col.add_field :api_pass_result
                  col.add_field :api_default_result
                end
                row.column do |col|
                  col.add_field :applies_to_all_markets
                  col.add_field :applicable_tm_group_ids
                  col.add_field :applies_to_all_cultivars
                  col.add_field :applicable_commodity_group_ids
                  col.add_field :applicable_cultivar_ids
                  # col.add_field :applies_to_orchard
                  # col.add_field :allow_result_capturing
                  # col.add_field :pallet_level_result
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
