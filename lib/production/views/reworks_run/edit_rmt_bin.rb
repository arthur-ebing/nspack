# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class EditRmtBin
        def self.call(reworks_run_type_id, bin_number,  form_values: nil, form_errors: nil, back_url:)
          ui_rule = UiRules::Compiler.new(:reworks_run_rmt_bin, :edit_rmt_bin, bin_number: bin_number, reworks_run_type_id: reworks_run_type_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.form do |form|
              form.action "/production/reworks/reworks_run_types/#{reworks_run_type_id}/pallets/#{bin_number}/edit_rmt_bin"
              form.row do |row|
                row.column do |col|
                  col.add_field :bin_number
                  col.add_field :reworks_run_type_id
                  col.add_field :rmt_class_id
                  col.add_field :rmt_size_id
                  col.add_field :rmt_container_material_type_id
                  col.add_field :rmt_material_owner_party_role_id
                end
                row.blank_column
              end
            end
          end

          layout
        end
      end
    end
  end
end
