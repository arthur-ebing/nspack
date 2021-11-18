# frozen_string_literal: true

module FinishedGoods
  module Dispatch
    module Load
      class ContainerWeights
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:load, :container_weights, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_text rules[:compact_header]
              section.add_control control_type: :link,
                                  text: 'Verified Gross Mass',
                                  url: "/finished_goods/reports/verified_gross_mass/#{id}",
                                  loading_window: true,
                                  style: :button
            end

            page.form do |form|
              form.action "/finished_goods/dispatch/loads/#{id}/container_weights"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :container_code
                  col.add_field :container_seal_code
                  col.add_field :max_gross_weight
                  col.add_field :max_payload
                end
                row.column do |col|
                  col.add_field :verified_gross_weight
                  col.add_field :internal_container_code
                  col.add_field :tare_weight
                  col.add_field :actual_payload
                end
              end
            end
          end
        end
      end
    end
  end
end
