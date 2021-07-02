# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class Search
        def self.call(back_url: nil, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:load_search, :new, form_values: form_values)
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
            page.form do |form|
              form.action '/finished_goods/dispatch/loads/search_load_by_pallet'
              form.caption 'Search loads by pallet number'

              form.row do |row|
                row.column do |col|
                  col.add_field :pallet_number
                end
                row.column do |col|
                  col.add_field :spacer
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
