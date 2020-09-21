# frozen_string_literal: true

module UiRules
  class DeliveryBatchRule < Base
    def generate_rules
      make_form_object
      apply_form_values
      common_values_for_fields common_fields

      form_name 'rmt_delivery'
    end

    def common_fields
      { batch_number: {} }
    end

    def make_form_object
      @form_object = OpenStruct.new(orchard_id: nil)
    end
  end
end
