# frozen_string_literal: true

module UiRules
  class AddendumPlaceOfIssueRule < Base
    def generate_rules
      make_new_form_object
      common_values_for_fields common_fields
      form_name 'addendum_place_of_issue'
    end

    def common_fields
      {
        place_of_issue: {
          renderer: :select,
          options: [AppConst::ADDENDUM_PLACE_OF_ISSUE, 'CPT'].uniq,
          required: true
        }

      }
    end

    def make_new_form_object
      @form_object = OpenStruct.new(place_of_issue: AppConst::ADDENDUM_PLACE_OF_ISSUE)
    end
  end
end
