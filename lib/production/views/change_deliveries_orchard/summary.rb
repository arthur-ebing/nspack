# frozen_string_literal: true

module Production
  module Reworks
    module ChangeDeliveriesOrchard
      class Summary
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:apply_change_deliveries_orchard_changes, :select_orchards, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form| # rubocop:disable Metrics/BlockLength
              form.action '/production/reworks/change_deliveries_orchard/apply_change_deliveries_orchard_changes'
              form.submit_captions 'Apply Changes'
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_text 'You Are About To Change Orchard'
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :from_orchard
                  col.add_field :from_ochard_code
                  if form_values[:from_cultivar]
                    col.add_field :from_cultivar
                    col.add_field :from_cultivar_name
                  end
                  col.add_field :to_orchard
                  col.add_field :to_ochard_code
                  col.add_field :to_cultivar
                  col.add_field :to_cultivar_name
                  col.add_field :allow_cultivar_mixing
                  col.add_field :ignore_runs_that_allow_mixing
                  col.add_text 'For The Following Objects'
                  col.add_text rules[:compact_header]
                  col.add_field :affected_deliveries
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
