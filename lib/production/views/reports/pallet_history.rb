# frozen_string_literal: true

module Production
  module Reports
    module PalletHistory
      class Show
        def self.call(data)
          Crossbeams::Layout::Page.build({}) do |page|
            page.add_text "Pallet number: #{data[:pallet_number]}"
            page.section do |section|
              section.add_control control_type: :link,
                                  style: :action_button,
                                  text: 'Check extended FG codes',
                                  url: "/production/reports/pallet_history/pallet/#{data[:id]}/extended_fg_codes",
                                  icon: :checkon,
                                  behaviour: :popup
            end
          end
        end
      end
    end
  end
end
