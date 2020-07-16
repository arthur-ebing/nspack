# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ManageSequenceCartons
        def self.call(pallet_sequence_id, back_url: request.referer)
          ui_rule = UiRules::Compiler.new(:reworks_run_carton, :manage, id: pallet_sequence_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_grid('reworks_pallet_sequence_cartons',
                               "/list/reworks_pallet_sequence_cartons/grid?key=pallet_sequence_cartons&pallet_sequence_id=#{pallet_sequence_id}",
                               caption: 'Pallet Sequence Cartons',
                               height: 35)
            end
          end

          layout
        end
      end
    end
  end
end
