# frozen_string_literal: true

module UiRules
  class LoadSearchRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::LoadRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      form_name 'load_search'
    end

    def common_fields
      {
        pallet_number: { renderer: :input,
                         subtype: :integer,
                         required: true },
        spacer: { hide_on_load: true }
      }
    end

    def make_form_object
      @form_object = OpenStruct.new(pallet_number: nil)
    end
  end
end
