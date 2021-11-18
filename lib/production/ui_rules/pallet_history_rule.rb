# frozen_string_literal: true

module UiRules
  class PalletHistoryRule < Base
    def generate_rules
      make_new_form_object
      common_values_for_fields pallet_field
      # common_values_for_fields common_fields
      form_name 'pallet_history'
    end

    def pallet_field
      {
        pallet_number: {}
      }
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pallet_number: nil)
    end
  end
end
