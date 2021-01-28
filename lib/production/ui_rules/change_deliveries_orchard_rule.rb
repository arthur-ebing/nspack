# frozen_string_literal: true

module UiRules
  class ChangeDeliveriesOrchardRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      make_new_form_object
      apply_form_values

      common_values_for_fields common_fields
      add_behaviours

      form_name 'change_deliveries_orchard'
    end

    def common_fields
      fields = {
        allow_cultivar_mixing: { renderer: :checkbox },
        from_orchard: { renderer: :select, options: MasterfilesApp::FarmRepo.new.find_farm_orchards, required: true, prompt: true },
        from_cultivar: { renderer: :select, options: [], required: true, prompt: true },
        to_orchard: { renderer: :select, options: [], required: true, prompt: true },
        to_cultivar: { renderer: :select, options: [], required: true, prompt: true },
        ignore_runs_that_allow_mixing: { renderer: :checkbox }

      }

      fields
    end

    def make_new_form_object
      @form_object = OpenStruct.new(from_orchard: nil, to_orchard: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.input_change :allow_cultivar_mixing, notify: [{ url: '/production/reworks/change_deliveries_orchard/allow_cultivar_mixing_changed' }]
        behaviour.dropdown_change :from_orchard, notify: [{ url: '/production/reworks/change_deliveries_orchard/from_orchard_combo_changed' }]
        behaviour.dropdown_change :to_orchard, notify: [{ url: '/production/reworks/change_deliveries_orchard/to_orchard_combo_changed' }]
      end
    end
  end
end
