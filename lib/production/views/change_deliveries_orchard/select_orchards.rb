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
              form.remote! if remote
              form.add_field :allow_cultivar_mixing
              form.add_field :from_orchard
              form.add_field :from_cultivar
              form.add_field :to_orchard
              form.add_field :to_cultivar
              form.submit_captions 'Next'
            end
          end

          layout
        end
      end
    end
  end
end
