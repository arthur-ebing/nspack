# frozen_string_literal: true

module UiRules
  class BinsTripsheetRule < Base
    def generate_rules
      make_form_object

      common_values_for_fields common_fields

      form_name 'bins_tripsheet'
    end

    def common_fields
      { planned_location_to_id: { renderer: :select,
                                  options: MasterfilesApp::LocationRepo.new.find_locations_by_location_type_and_storage_type(AppConst::LOCATION_TYPES_WAREHOUSE, AppConst::STORAGE_TYPE_BINS),
                                  caption: 'Location',
                                  required: true } }
    end

    def make_form_object
      @form_object = OpenStruct.new(planned_location_to_id: nil)
    end
  end
end
