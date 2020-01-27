# frozen_string_literal: true

module Production
  module Reworks
    module ChangeDeliveriesOrchard
      class Summary
        def self.call(form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:apply_change_deliveries_orchard_changes, :select_orchards, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.add_text 'You Are About To Change Orchard'
              form.action '/production/reworks/change_deliveries_orchard/apply_change_deliveries_orchard_changes'
              form.remote! if remote
              form.add_field :from
              form.add_field :to
              form.add_field :to_cultivar
              form.add_text 'For The Following Deliveries'
              form.add_field :affected_deliveries
              form.submit_captions 'Apply Changes'
            end
          end

          layout
        end
      end
    end
  end
end
