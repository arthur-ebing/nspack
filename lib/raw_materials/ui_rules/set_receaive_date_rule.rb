# frozen_string_literal: true

module UiRules
  class SetReceiveDateRule < Base
    def generate_rules
      @repo = RawMaterialsApp::RmtDeliveryRepo.new

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      form_name 'rmt_delivery'
    end

    def common_fields
      {
        date_received: { required: true, renderer: :datetime, caption: 'Set Date Received' },
        date_delivered: { renderer: :label, caption: 'Date Received' }
      }
    end

    def make_form_object
      @form_object = @repo.find_rmt_delivery(@options[:id]).to_h.merge(date_received: Time.now)
    end
  end
end
