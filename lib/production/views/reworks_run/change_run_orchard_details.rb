# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ChangeRunOrchardDetails
        def self.call(reworks_run_type_id, attrs, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:change_run_orchard, :details, reworks_run_type_id: reworks_run_type_id, attrs: attrs, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/production/reworks/reworks_run_types/change_run_orchard/reworks_runs/new',
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.form do |form|
              form.view_only!
              form.no_submit!
              # form.action "/production/reworks/pallet_sequences/#{id}/edit_reworks_pallet_sequence"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type
                  col.add_field :orchard_id
                  col.add_field :allow_orchard_mixing
                  col.add_field :allow_cultivar_mixing
                  col.add_field :allow_cultivar_group_mixing
                end
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :production_run_id
                  col.add_field :from_orchard_id
                  col.add_text '',
                               dom_id: 'change_run_orchard_error_description',
                               css_classes: 'orange b'
                end
              end
            end
            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_control(id: 'change_run_orchard_accept_button',
                                  control_type: :link,
                                  text: 'Accept',
                                  url: '/production/reworks/change_run_orchard/submit_change_run_orchard',
                                  style: :button,
                                  visible: false)
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
