# frozen_string_literal: true

module Production
  module Reworks
    module ChangeDeliveriesOrchard
      # FIX: remove the _id parameter
      class FromOrchardDeliveries
        def self.call(_id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:change_deliveries_orchard, :select_orchards, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              multiselect_params = { key: 'standard', orchard_id: form_values[:from_orchard] }
              if form_values[:allow_cultivar_mixing] == 'f'
                multiselect_params[:key] = 'disallow_cultivar_mixing'
                multiselect_params[:cultivar_id] = form_values[:from_cultivar]
              end
              section.add_grid('orchard_deliveries_grid',
                               '/list/change_deliveries_orchards/grid_multi',
                               caption: 'Choose Deliveries',
                               is_multiselect: true,
                               multiselect_url: '/production/reworks/change_deliveries_orchard/selected_deliveries',
                               multiselect_key: multiselect_params[:key],
                               multiselect_params: multiselect_params)
            end
          end

          layout
        end
      end
    end
  end
end
