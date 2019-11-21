# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class ShowPalletSequenceChanges
        def self.call(id, attrs, back_url:)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_pallet, :show_changes, id: id, attrs: attrs)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_notice 'The changes below were made to pallets affected list:'
            page.section do |section|
              section.add_diff :changes_made
            end
            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_control(control_type: :link,
                                  text: 'Accept',
                                  url: "/production/reworks/pallet_sequences/#{id}/accept_pallet_sequence_changes",
                                  style: :button)
                  col.add_control(control_type: :link,
                                  text: 'Reject',
                                  url: "/production/reworks/pallet_sequences/#{id}/reject_pallet_sequence_changes",
                                  style: :button)
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
