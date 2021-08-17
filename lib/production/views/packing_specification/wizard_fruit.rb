# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecification
      class WizardFruit
        def self.call(form_values: nil, form_errors: nil)
          mode = form_values[:mode] || :new
          ui_rule = UiRules::Compiler.new(:packing_specification_wizard_fruit, mode, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
              section.add_control(control_type: :link,
                                  text: 'Cancel',
                                  url: '/production/packing_specifications/wizard/cancel',
                                  style: :button,
                                  css_class: 'bg-light-red')
            end
            page.section do |section|
              section.show_border!
              section.add_text "Packing Specification Code: #{ui_rule.form_object.packing_specification_code}"
            end
            page.section do |section|
              section.fold_up do |fold|
                # fold.open!
                fold.caption 'Packing Specification'
                fold.add_text rules[:compact_header]
              end
            end
            page.form do |form|
              form.caption 'Packing Spec Wizard - Fruit'
              form.submit_captions 'Next'
              form.action '/production/packing_specifications/wizard'
              form.row do |row|
                row.column do |col|
                  col.add_field :product_setup_template_id
                  col.add_field :commodity_id
                  col.add_field :marketing_variety_id
                  col.add_field :std_fruit_size_count_id
                  col.add_field :basic_pack_code_id
                  col.add_field :standard_pack_code_id
                end
                row.column do |col|
                  col.add_field :fruit_actual_counts_for_pack_id
                  col.add_field :fruit_size_reference_id
                  col.add_field :rmt_class_id
                  col.add_field :grade_id
                  col.add_field :colour_percentage_id
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
