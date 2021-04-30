# frozen_string_literal: true

module UiRules
  class IntakeTripsheetRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      # apply_form_values

      common_values_for_fields common_fields

      form_name 'intake_tripsheet'
    end

    def common_fields
      { location_to_id: { renderer: :select,
                          options: MasterfilesApp::LocationRepo.new.for_select_location_for_assignment(AppConst::WAREHOUSE_RECEIVING_AREA),
                          caption: 'Location',
                          required: true } }
    end

    def make_form_object
      @form_object = OpenStruct.new(location_to_id: nil)
    end
  end
end
