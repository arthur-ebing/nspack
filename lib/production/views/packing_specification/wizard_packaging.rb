# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecification
      class WizardPackaging
        def self.call(form_values: nil, form_errors: nil)
          mode = form_values[:mode] || :new
          ui_rule = UiRules::Compiler.new(:packing_specification_wizard_packaging, mode, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
              section.add_control(control_type: :link,
                                  text: 'Previous',
                                  url: '/production/packing_specifications/wizard/previous',
                                  style: :action_button)
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
              form.caption 'Packing Spec Wizard - Packaging'
              form.submit_captions ui_rule.form_object.submit_caption
              form.action ui_rule.form_object.action
              form.row do |row|
                row.column do |col|
                  col.add_field :pallet_base_id
                  col.add_field :pallet_stack_type_id
                  col.add_field :pallet_format_id
                end
                row.column do |col|
                  col.add_field :pallet_label_name
                  col.add_field :cartons_per_pallet_id
                  col.add_field :carton_label_template_id
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
