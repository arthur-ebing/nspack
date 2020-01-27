# frozen_string_literal: true

module UiRules
  class ApplyChangeDeliveriesOrchardChangesRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      apply_form_values

      common_values_for_fields common_fields

      form_name 'summary'
    end

    def common_fields
      fields = {
        from: { renderer: :label },
        to: { renderer: :label },
        to_cultivar: { renderer: :label },
        affected_deliveries: { renderer: :textarea,
                               rows: 15,
                               disabled: true,
                               caption: '' }
      }

      fields
    end
  end
end
