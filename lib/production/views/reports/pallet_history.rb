# frozen_string_literal: true

module Production
  module Reports
    module PalletHistory
      class Show
        def self.call(data)
          Crossbeams::Layout::Page.build({}) do |page|
            page.add_text "Pallet number: #{data[:pallet_number]}"
            page.section do |section|
              section.add_control(control_type: :dropdown_button,
                                  text: 'Check extended FG codes',
                                  items: [
                                    { url: "/production/reports/pallet_history/pallet/#{data[:id]}/extended_fg_codes",
                                      text: 'Show possible FG codes',
                                      behaviour: :popup },
                                    { url: "/production/reports/pallet_history/pallet/#{data[:id]}/extended_fg_codes_with_lookup",
                                      text: 'Show FG codes and do lookup of id',
                                      behaviour: :popup }
                                  ])
              section.add_control control_type: :link,
                                  style: :action_button,
                                  text: 'Status',
                                  url: "/development/statuses/list/pallets/#{data[:id]}",
                                  icon: :info,
                                  behaviour: :popup
            end
          end
        end
      end
    end
  end
end
