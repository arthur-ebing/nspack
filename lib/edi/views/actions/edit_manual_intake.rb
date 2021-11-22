# frozen_string_literal: true

module Edi
  module Actions
    module Edit
      class ManualIntake
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:edi_manual_intake, :edit, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.method :update
              form.caption 'Manual intake'
              form.action "/edi/actions/edit_manual_intake/#{id}"
              form.add_field :depot_id
              form.add_field :edi_in_inspection_point
              form.add_field :edi_in_load_number
            end

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/edi_in_transactions/with_params?key=manual_intakes',
                                  style: :back_button)
              section.add_control(control_type: :link,
                                  text: 'Add a row',
                                  icon: :plus,
                                  # behaviour: :popup,
                                  grid_id: 'manual_intake_items',
                                  url: "/edi/actions/edit_manual_intake/#{id}/add_row",
                                  style: :button)
            end

            page.add_grid('manual_intake_items',
                          "/edi/actions/edit_manual_intake/#{id}/grid",
                          caption: 'Manual intake items')
          end
        end
      end
    end
  end
end
