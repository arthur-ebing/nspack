# frozen_string_literal: true

module Quality
  module Qc
    module QcSample
      class Manage
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qc_sample, :manage, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.add_text rules[:heading1], wrapper: :h1
            page.add_text rules[:heading2], wrapper: :h2, css_classes: 'pa0'
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_control control_type: :link, text: 'Back', url: '/list/qc_samples/with_params?key=incomplete', style: :back_button
              section.add_control(control_type: :dropdown_button, text: 'Production Run QC', items: rules[:items_prodrun]) unless rules[:items_prodrun].empty?
              section.add_control(control_type: :dropdown_button, text: 'Presort Run QC', items: rules[:items_presort]) unless rules[:items_presort].empty?
            end
            page.row do |row|
              row.column do |col|
                col.add_text rules[:qc_summary][:caption], wrapper: :h3, css_classes: 'mid-gray'
                if rules[:qc_summary][:items].empty?
                  col.add_text 'No sample', wrapper: :em
                else
                  col.add_table rules[:qc_summary][:items],
                                %i[key sample_size status summary],
                                alignment: { sample_size: :right }
                end
              end
            end
          end
        end
      end
    end
  end
end
