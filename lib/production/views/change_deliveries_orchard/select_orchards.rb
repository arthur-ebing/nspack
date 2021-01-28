# frozen_string_literal: true

module Production
  module Reworks
    module ChangeDeliveriesOrchard
      class SelectOrchards
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:change_deliveries_orchard, :select_orchards, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Change Deliveries Orchard'
              form.action '/production/reworks/change_deliveries_orchard'
              form.submit_captions 'Next'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :allow_cultivar_mixing
                  col.add_field :from_orchard
                  col.add_field :from_cultivar
                  col.add_field :to_orchard
                  col.add_field :to_cultivar
                  col.add_field :ignore_runs_that_allow_mixing
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
